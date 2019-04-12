# frozen_string_literal: true

require 'dry-struct'

module CA
  # :reek:UncommunicativeModuleName
  module SSH
    # Represents a user or host's request for a signed certificate
    class CertificateRequest < Dry::Struct
      class << self
        # :reek:LongParameterList
        # Creates a certificate request from a config hash
        def from_hash(
          role:,
          public_key:,
          principals:,
          public_key_format: nil,
          ttl: nil,
          **_other
        )
          CertificateRequest.new(
            requested_by: role,
            public_key: public_key(public_key, public_key_format),
            principals: principals(principals),
            ttl: ttl(ttl)
          )
        end

        private

        def public_key(public_key_data, public_key_format)
          raise ArgumentError, "Request is missing public key for signing" if public_key_data.to_s.strip.empty?

          public_key_format = public_key_format.to_s
          key_format = public_key_format.strip.empty? ? :openssh : public_key_format.downcase.to_sym

          Util::SSH::PublicKey.new(public_key_data, key_format)
        end
  
        def principals(principals)
          principals = Array(principals).reject { |val| val.to_s.strip.empty? }

          raise ArgumentError, "Signing parameter 'principals' is missing" if principals.empty?

          principals
        end

        def ttl(ttl)
          return nil if ttl.to_s.strip.empty?

          ISO8601::Duration.new(ttl).to_seconds.to_i
        end
      end

      attribute :requested_by, Types.Definition(Role)
      attribute :public_key, Types.Definition(Util::SSH::PublicKey)
      attribute :principals, Types::Strict::Array.of(Types::Coercible::String)
      attribute :ttl, Types::Strict::Nil | Types::Strict::Int.constrained(gt: 0)
    end
  end
end
