module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Represents a signed x.509 certificate
    class Certificate < Dry::Struct
      attribute :certificate, Types.Definition(OpenSSL::X509::Certificate)

      def to_formatted
        FormattedCertificate.new(content: certificate.to_pem, content_type: 'application/x-pem-file')
      end
    end
  end
end
