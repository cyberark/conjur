module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Issuer represent the CA signing key material stored in Conjur
    class Issuer < Dry::Struct::Value
      class << self
        def from_resource(resource)
          config = ::CA::Configuration.new(resource)

          Issuer.new(
            private_key: config.rsa_private_key,
            certificate: certificate(config),
            max_ttl: config.max_ttl,
            issuer_id: service_id(resource)
          )
        end

        def certificate(config)
          cert = config.variable('ca/certificate') do |cert_data|
            OpenSSL::X509::Certificate.new cert_data
          end

          unless cert
            raise ArgumentError, "The certificate (ca/certificate) for '#{service_id}' is missing." 
          end

          cert
        end

        def service_id(resource)
          # CA services have ids like 'conjur/ca/<service_id>'
          resource.identifier.split('/')[2]
        end
      end

      attribute :private_key, Types.Definition(OpenSSL::PKey::RSA)
      attribute :certificate, Types.Definition(OpenSSL::X509::Certificate)
      attribute :max_ttl, Types::Strict::Int.constrained(gt: 0)
      attribute :issuer_id, Types::Strict::String

      def subject
        certificate.subject
      end
    end
  end
end
