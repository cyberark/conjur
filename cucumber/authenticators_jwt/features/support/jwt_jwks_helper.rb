# frozen_string_literal: true

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
  BITS_2048 = 2048
  HOUR_IN_SECONDS = 3600
  HMAC_SECRET = 'my$ecretK3y'

  def init_jwks_file(file_name)
    @default_file_name ||= file_name
    add_new_file(file_name)
    jwks = { keys: [jwk_set[file_name].export] }
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
      JSON.pretty_generate(jwks)
    )
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

  def init_ecdsa_jwks_file(file_name, key_type)
    @default_file_name ||= file_name
    @key_type = key_type
    jwks = { keys: [jwk_ecdsa.export] }
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
      JSON.pretty_generate(jwks)
    )
  end

  def init_hmac_jwks_file(file_name)
    @default_file_name ||= file_name
    jwks = { keys: [jwk_hmac.export] }
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
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

  def issue_none_alg_jwt_token(token_body)
    token_header_and_payload = JWT.encode(
      token_body,
      nil,
      'none',
      {
        kid: jwk_set[@default_file_name].kid
      }
    )
    @jwt_token = "#{token_header_and_payload}invalid_singature"
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

  def issue_jwt_ecdsa_token(token_body, algorithm = Algorithms::ES256)
    @jwt_token = JWT.encode(
      token_body,
      ecdsa_private_key,
      algorithm,
      {
        kid: jwk_ecdsa.kid
      }
    )
  end

  def issue_jwt_hmac_token(token_body, algorithm = Algorithms::HS256)
    @jwt_token = JWT.encode(
      token_body,
      HMAC_SECRET,
      algorithm
    )
  end

  def issue_rsa_jwt_token_with_alg_header(token_body, alg_header, algorithm = Algorithms::RS256)
    encoded_token = JWT.encode(
      token_body,
      rsa_keys[@default_file_name],
      algorithm
    )
    token_parts = encoded_token.split(".")
    headers = "{\"typ\":\"JWT\",\"alg\":\"#{alg_header}\",\"kid\":\"#{jwk_set[@default_file_name].kid}\"}"
    token_parts[0] = Base64.urlsafe_encode64(headers).strip
    @jwt_token = token_parts.join(".")
  end

  def issue_jwt_hmac_token_token_with_rsa_key(token_body)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[@default_file_name].to_s,
      Algorithms::HS256,
      {
        kid: jwk_set[@default_file_name].kid
      }
    )
  end

  def jwt_token
    @jwt_token
  end

  def jwk_ecdsa
    @jwk_ecdsa ||= JWT::JWK::EC.new(ecdsa_public_key)
  end

  def jwk_hmac
    @jwk_hmac ||= JWT::JWK::HMAC.new(HMAC_SECRET)
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

  def ecdsa_private_key
    @ecdsa_private_key ||= create_ecdsa_key
  end

  def ecdsa_public_key
    @ecdsa_public_key ||= create_ecdsa_public
  end

  def create_ecdsa_key
    ecdsa_key = OpenSSL::PKey::EC.new(@key_type)
    ecdsa_key.generate_key
    ecdsa_key
  end

  def create_ecdsa_public
    ecdsa_public = OpenSSL::PKey::EC.new(ecdsa_private_key)
    ecdsa_public.private_key = nil
    ecdsa_public
  end

  def token_body_with_valid_expiration(token_body)
    if token_body["exp"].nil?
      token_body["exp"] = Time.now.to_i + HOUR_IN_SECONDS
    end
    token_body
  end
end

World(JwtJwksHelper)
