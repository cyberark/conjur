# frozen_string_literal: true

# Cryptography is used to define HMAC or hash-based message authentication code
# this is used to hash the api key
module Cryptography
  extend ActiveSupport::Concern
  module_function
  def hmac_api_key(pass, salt)
    iter = 20
    key_len = 32
    OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter, length: key_len, hash: "sha256")
  end
end

    
