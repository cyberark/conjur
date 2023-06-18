module Slosilo
  class Error < RuntimeError
    # An error thrown when attempting to store a private key in an unecrypted
    # storage. Set Slosilo.encryption_key to secure the storage or make sure
    # to store just the public keys (using Key#public).
    class InsecureKeyStorage < Error
      def initialize msg = "can't store a private key in a plaintext storage"
        super
      end
    end

    class TokenValidationError < Error
    end
  end
end
