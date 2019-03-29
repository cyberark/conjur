module CA
  # :reek:UncommunicativeModuleName
  module X509
    # SignatoryCertificate represent the CA signing key stored in Conjur
    class Issuer < Dry::Struct
      attribute :service, Types.Definition(::CA::Webservice)

      def private_key
        @private_key ||= Util::OpenSsl::PrivateKey.from_hash(
          key: key_data,
          password: key_password
        )
      end

      def subject
        certificate.subject
      end

      def certificate
        # Parse the first certificate in the chain, which should be the
        # CA certificate
        @certificate ||= OpenSSL::X509::Certificate.new cert_data
      end

      private

      def cert_data
        @cert_data ||= service.variable_annotation('ca/certificate')
      end

      def key_data
        @key_data ||= service.variable_annotation('ca/private-key')
      end

      def key_password
        @key_password ||= service.variable_annotation('ca/private-key-password')
      end
    end
  end
end
