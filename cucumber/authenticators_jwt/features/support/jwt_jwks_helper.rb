# frozen_string_literal: true

require 'openssl'
require 'jwt'

# Utility methods for JWT and JWKs manipulation
module JwtJwksHelper

  module Algorithms
    RS256 = "RS256"
  end

  JWKS_ROOT_PATH = "/var/jwks"
  JWKS_BASE_URI = "http://jwks"
  BITS_2048 = 2048
  HOUR_IN_SECONDS = 3600

  def init_jwks_file(file_name)
    add_new_file(file_name)
    jwks = { keys: [jwk_set[file_name].export] }
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}",
      JSON.pretty_generate(jwks)
    )
  end

  def init_second_jwks_file_with_same_kid(first_file_name,second_file_name)
    add_new_file(second_file_name)
    jwk = jwk_set[second_file_name].export
    jwk["kid".to_sym] = jwk_set[first_file_name].export["kid".to_sym]
    jwks = { keys: [jwk] }

    File.write(
      "#{JWKS_ROOT_PATH}/#{second_file_name}",
      JSON.pretty_generate(jwks)
    )
  end

  def issue_jwt_token(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys.values[0],
      algorithm,
      { kid: jwk_set.values[0].kid }
    )
  end

  def issue_jwt_token_with_jku(token_body, algorithm = Algorithms::RS256, file_name)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[file_name],
      algorithm,
      { kid: jwk_set.values[0].kid,
        jku: JWKS_ROOT_PATH + '/' +  file_name }
    )
  end

  def issue_jwt_token_with_jwk(token_body, algorithm = Algorithms::RS256, file_name)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys[file_name],
      algorithm,
      { kid: jwk_set.values[0].kid,
        jwk: rsa_keys[file_name] }
    )
  end

  def issue_jwt_token_unkown_kid(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      rsa_keys.values[0],
      algorithm,
      { kid: "unknown_kid"}
    )
  end

  def issue_jwt_token_not_memoized_key(token_body, algorithm = Algorithms::RS256)
    @jwt_token = JWT.encode(
      token_body,
      generate_rsa_key,
      algorithm,
      { kid: jwk_set.values[0].kid }
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
    rsa_keys[file_name] = generate_rsa_key
  end

  def rsa_keys
    @rsa_keys ||= {}
  end

  def generate_rsa_key
    OpenSSL::PKey::RSA.new(BITS_2048)
  end

  def token_body_with_valid_expiration(token_body)
    if token_body["exp"].nil?
      token_body["exp"] = Time.now.to_i + HOUR_IN_SECONDS
    end
    token_body
  end
end

World(JwtJwksHelper)
