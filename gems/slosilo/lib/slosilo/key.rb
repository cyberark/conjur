require 'openssl'
require 'json'
require 'base64'
require 'time'

require 'slosilo/errors'

module Slosilo
  class Key
    def initialize raw_key = nil
      @key = if raw_key.is_a? OpenSSL::PKey::RSA
        raw_key
      elsif !raw_key.nil?
        OpenSSL::PKey.read raw_key
      else
        OpenSSL::PKey::RSA.new 2048
      end
    rescue OpenSSL::PKey::PKeyError => e
      # old openssl versions used to report ArgumentError
      # which arguably makes more sense here, so reraise as that
      raise ArgumentError, e, e.backtrace
    end
    
    attr_reader :key
    
    def cipher
      @cipher ||= Slosilo::Symmetric.new
    end
    
    def encrypt plaintext
      key = cipher.random_key
      ctxt = cipher.encrypt plaintext, key: key
      key = @key.public_encrypt key
      [ctxt, key]
    end

    def encrypt_message plaintext
      c, k = encrypt plaintext
      k + c
    end
    
    def decrypt ciphertext, skey
      key = @key.private_decrypt skey
      cipher.decrypt ciphertext, key: key
    end

    def decrypt_message ciphertext
      k, c = ciphertext.unpack("A256A*")
      decrypt c, k
    end
    
    def to_s
      @key.public_key.to_pem
    end
    
    def to_der
      @to_der ||= @key.to_der
    end
    
    def sign value
      sign_string(stringify value)
    end
    
    SIGNATURE_LEN = 256
    
    def verify_signature data, signature
      signature, salt = signature.unpack("a#{SIGNATURE_LEN}a*")
      key.public_decrypt(signature) == hash_function.digest(salt + stringify(data))
    rescue
      false
    end

    # create a new timestamped and signed token carrying data
    def signed_token data
      token = { "data" => data, "timestamp" => Time.new.utc.to_s }
      token["signature"] = Base64::urlsafe_encode64(sign token)
      token["key"] = fingerprint
      token
    end

    JWT_ALGORITHM = 'conjur.org/slosilo/v2'.freeze

    # Issue a JWT with the given claims.
    # `iat` (issued at) claim is automatically added.
    # Other interesting claims you can give are:
    # - `sub` - token subject, for example a user name;
    # - `exp` - expiration time (absolute);
    # - `cidr` (Conjur extension) - array of CIDR masks that are accepted to
    #   make requests that bear this token
    def issue_jwt claims
      token = Slosilo::JWT.new claims
      token.add_signature \
          alg: JWT_ALGORITHM,
          kid: fingerprint,
          &method(:sign)
      token.freeze
    end

    DEFAULT_EXPIRATION = 8 * 60
    
    def token_valid? token, expiry = DEFAULT_EXPIRATION
      return jwt_valid? token if token.respond_to? :header
      token = token.clone
      expected_key = token.delete "key"
      return false if (expected_key and (expected_key != fingerprint))
      signature = Base64::urlsafe_decode64(token.delete "signature")
      (Time.parse(token["timestamp"]) + expiry > Time.now) && verify_signature(token, signature)
    end

    # Validate a JWT.
    #
    # Convenience method calling #validate_jwt and returning false if an
    # exception is raised.
    #
    # @param token [JWT] pre-parsed token to verify
    # @return [Boolean]
    def jwt_valid? token
      validate_jwt token
      true
    rescue
      false
    end

    # Validate a JWT.
    #
    # First checks whether algorithm is 'conjur.org/slosilo/v2' and the key id
    # matches this key's fingerprint. Then verifies if the token is not expired,
    # as indicated by the `exp` claim; in its absence tokens are assumed to
    # expire in `iat` + 8 minutes.
    #
    # If those checks pass, finally the signature is verified.
    #
    # @raises TokenValidationError if any of the checks fail.
    #
    # @note It's the responsibility of the caller to examine other claims
    # included in the token; consideration needs to be given to handling
    # unrecognized claims.
    #
    # @param token [JWT] pre-parsed token to verify
    def validate_jwt token
      def err msg
        raise Error::TokenValidationError, msg, caller
      end

      header = token.header
      err 'unrecognized algorithm' unless header['alg'] == JWT_ALGORITHM
      err 'mismatched key' if (kid = header['kid']) && kid != fingerprint
      iat = Time.at token.claims['iat'] || err('unknown issuing time')
      exp = Time.at token.claims['exp'] || (iat + DEFAULT_EXPIRATION)
      err 'token expired' if exp <= Time.now
      err 'invalid signature' unless verify_signature token.string_to_sign, token.signature
      true
    end
    
    def sign_string value
      salt = shake_salt
      key.private_encrypt(hash_function.digest(salt + value)) + salt
    end
    
    def fingerprint
      @fingerprint ||= OpenSSL::Digest::SHA256.hexdigest key.public_key.to_der
    end

    def == other
      to_der == other.to_der
    end

    alias_method :eql?, :==

    def hash
      to_der.hash
    end

    # return a new key with just the public part of this
    def public
      Key.new(@key.public_key)
    end

    # checks if the keypair contains a private key
    def private?
      @key.private?
    end
    
    private
    
    # Note that this is currently somewhat shallow stringification -- 
    # to implement originating tokens we may need to make it deeper.
    def stringify value
      string = case value
      when Hash
        value.to_a.sort.to_json
      when String
        value
      else
        value.to_json
      end

      # Make sure that the string is ascii_8bit (i.e. raw bytes), and represents
      # the utf-8 encoding of the string.  This accomplishes two things: it normalizes
      # the representation of the string at the byte level (so we don't have an error if
      # one username is submitted as ISO-whatever, and the next as UTF-16), and it prevents
      # an incompatible encoding error when we concatenate it with the salt.
      if string.encoding != Encoding::ASCII_8BIT
        string.encode(Encoding::UTF_8).force_encoding(Encoding::ASCII_8BIT)
      else
        string
      end
    end
    
    def shake_salt
      Slosilo::Random::salt
    end
    
    def hash_function
      @hash_function ||= OpenSSL::Digest::SHA256
    end
  end
end
