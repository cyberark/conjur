module CA
  module SSH
    # Issuer represent the CA signing key material stored in Conjur
    class Issuer < Dry::Struct
      class << self
        def from_resource(resource)
          config = ::CA::Configuration.new(resource)

          Issuer.new(
            private_key: config.rsa_private_key,
            max_ttl: config.max_ttl
          )
        end
      end

      attribute :private_key, Types.Definition(OpenSSL::PKey::RSA)
      attribute :max_ttl, Types::Strict::Int.constrained(gt: 0)
    end
  end
end
