# frozen_string_literal: true

require 'rubygems'
require 'openssl'
require 'jwt'
require "base64"

# Utility methods for JWT and JWKs manipulation
module JwtJwksHelper

  module Algorithms
    RS256 = 'RS256'
    HS256 = 'HS256'
    ES256 = 'ES256'
  end

  JWKS_ROOT_PATH = "/var/jwks"
  JWKS_BASE_URI = "http://jwks"
  JWKS_REMOTE_BASE_URI = "http://jwks_py:8090"
  BITS_2048 = 2048
  HOUR_IN_SECONDS = 3600

  def init_jwks_file(file_name)
    @default_file_name ||= file_name
    add_new_file(file_name)
    jwks = { keys: [jwk_set[file_name].export] }
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
      JSON.pretty_generate(jwks)
    )
  end

  def init_jwks_remote_file(file_name, alg)
    path = "#{JWKS_REMOTE_BASE_URI}/#{file_name}/#{alg}"
    get(path)
  end

  def init_second_jwks_file_with_same_kid(first_file_name, second_file_name)
    add_new_file(second_file_name)
    jwk = jwk_set[second_file_name].export
    jwk[:kid] = jwk_set[first_file_name].export[:kid]
    jwks = { keys: [jwk] }

    File.write(
      "#{JWKS_ROOT_PATH}/#{second_file_name}",
      JSON.pretty_generate(jwks)
    )
  end

  def issue_jwt_token(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[@default_file_name],
      algorithm,
      {
        kid: jwk_set[@default_file_name].kid
      }
    )
  end

  def issue_jwt_token_remotely(file_name, alg, token_body)
    # the remote server receives well built token and (re)signs it
    token = JWT.encode(
      token_body,
      nil,
      'none'
    )
    path = "#{JWKS_REMOTE_BASE_URI}/#{file_name}/#{alg}"
    post(path, token)
    @jwt_token = @response_body
  end

  def issue_jwt_token_with_jku(token_body, file_name, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[file_name],
      algorithm,
      {
        kid: jwk_set[@default_file_name].kid,
        jku: "#{JWKS_ROOT_PATH}/#{file_name}"
      }
    )
  end

  def issue_jwt_token_with_jwk(token_body, file_name, algorithm = Algorithms::RS256)
    jwk = jwk_set[file_name].export
    jwk[:kid] = jwk_set[@default_file_name].kid

    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[file_name],
      algorithm,
      {
        kid: jwk_set[@default_file_name].kid,
        jwk: jwk
      }
    )
  end

  def issue_jwt_token_with_x5c(token_body, algorithm = Algorithms::RS256)
    x5c_file_name = "x5c.pem"
    add_new_file(x5c_file_name)
    cert = self_signed_certificate(rsa_keys[x5c_file_name])

    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[x5c_file_name],
      algorithm,
      {
        x5c:  [Base64.strict_encode64(cert.to_der)],
        x5t:  base64_x5t_from_certificate(cert)
      }
    )
  end

  def issue_jwt_token_with_x5u(token_body, file_name, algorithm = Algorithms::RS256)
    add_new_file(file_name)
    cert = self_signed_certificate(rsa_keys[file_name])
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
      JSON.pretty_generate(cert.to_pem.gsub("\n", ""))
    )

    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[file_name],
      algorithm,
      {
        x5u: "#{JWKS_ROOT_PATH}/#{file_name}",
      }
    )
  end

  def issue_none_alg_jwt_token(token_body)
    @jwt_token = JWT.encode(
      token_body,
      nil,
      'none'
    )
  end

  def issue_jwt_token_unkown_kid(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[@default_file_name],
      algorithm,
      { kid: "unknown_kid" }
    )
  end

  def issue_jwt_token_not_memoized_key(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      new_rsa_key,
      algorithm,
      { kid: jwk_set[@default_file_name].kid }
    )
  end

  def issue_jwt_hmac_token_with_rsa_key(token_body)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[@default_file_name].public_key.to_s,
      Algorithms::HS256,
      {
        kid: jwk_set[@default_file_name].kid
      }
    )
  end

  def jwt_token
    @jwt_token
  end

  def add_new_file(file_name)
    add_rsa_key_to_set(file_name)
    add_jwk_to_set(file_name)
  end

  def add_jwk_to_set(file_name)
    jwk_set[file_name] = JWT::JWK.new(rsa_keys[file_name])
  end

  def jwk_set
    @jwk_set ||= {}
  end

  def add_rsa_key_to_set(file_name)
    rsa_keys[file_name] = new_rsa_key
  end

  def rsa_keys
    @rsa_keys ||= {}
  end

  def new_rsa_key
    OpenSSL::PKey::RSA.new(BITS_2048)
  end

  def token_body_with_valid_expiration(token_body)
    if token_body["exp"].nil?
      token_body["exp"] = Time.now.to_i + HOUR_IN_SECONDS
    end
    token_body
  end

  def base64_x5t_from_certificate(cert)
    cert_thumbprint = OpenSSL::Digest::SHA256.hexdigest(cert.to_der)
    Base64.urlsafe_encode64(cert_thumbprint, padding: false)
  end

  def self_signed_certificate(rsa_key)
    subject = "/C=BE/O=Test/OU=Test/CN=Test"

    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
    cert.not_before = Time.now
    cert.not_after = Time.now + 365 * 24 * 60 * 60
    cert.public_key = rsa_key.public_key
    cert.serial = 0x0
    cert.version = 2
    cert.sign(rsa_key, OpenSSL::Digest.new('SHA256'))

    cert
  end
end

World(JwtJwksHelper)
