# frozen_string_literal: true

# A public key.
class PublicKey
  class << self
    # Extract the name of a key from an authorized_keys line, like "<algorithm> <key> <name>"
    def key_name key
      parts = key.split(' ', 3)
      raise "Invalid public key format" unless parts.count == 3
      parts[2]
    end
  end
end
