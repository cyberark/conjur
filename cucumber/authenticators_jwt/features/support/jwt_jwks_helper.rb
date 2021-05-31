# frozen_string_literal: true

# Utility methods for JWT and JWKs manipulation

require 'openssl'
require 'jwt'

module JwtJwksHelper

  module Algorithms
    RS256 = "RS256".freeze
  end

  JWKS_ROOT_PATH = "/var/jwks".freeze
  JWKS_BASE_URI = "http://jwks".freeze
  BITS_2048 = 2048.freeze
  HOUR_IN_SECONDS = 3600.freeze

  def init_jwks_file(file_name)
    File.write(
      "#{JWKS_ROOT_PATH}/#{file_name}", 
      JSON.pretty_generate({ keys: [state_entity(file_name)["jwk"].export] })
    )
  end

  def issue_jwt_token(token_body, key_name, algorithm = Algorithms::RS256)
    @state[key_name]["jwt_token"] = JWT.encode(
      token_body,
      @state[key_name]["rsa_key"],
      algorithm,
      { kid: @state[key_name]["jwk"].kid }
    )
  end

  def jwt_token(key_name)
    @state[key_name]["jwt_token"]
  end

  def token_body_with_valid_expiration(token_body)
    token_body["exp"] = Time.now.to_i + HOUR_IN_SECONDS
    token_body
  end

  private

  def jwk(rsa_key)
    JWT::JWK.new(rsa_key)
  end

  def rsa_key(length)
    OpenSSL::PKey::RSA.new(length)
  end

  def state_entity(name)
    rsa_key = rsa_key(BITS_2048)
    jwk = jwk(rsa_key)
    @state ||= {}
    @state[name] = {
      "rsa_key" => rsa_key,
      "jwk" => jwk
    }
  end

end

World(JwtJwksHelper)
