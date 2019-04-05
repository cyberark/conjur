module CA
  module SSH
    # Issuer represent the CA signing key material stored in Conjur
    class Issuer < Dry::Struct
      class << self
        include ::CA::AnnotationLoader::RsaPrivateKey
        include ::CA::AnnotationLoader::MaxTTL

        def from_resource(resource)
          annotations = ::CA::AnnotationLoader.new(resource)

          Issuer.new(
            private_key: load_rsa_private_key(annotations),
            max_ttl: load_max_ttl(annotations)
          )
        end
      end

      attribute :private_key, Types.Definition(OpenSSL::PKey::RSA)
      attribute :max_ttl, Types::Strict::Int.constrained(gt: 0)
    end
  end
end
