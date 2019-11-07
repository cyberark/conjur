module CA
  # :reek:UncommunicativeModuleName
  # Provides helper methods for creating the X509
  # value and command objects for certificate signing.
  module X509
    class << self
      def certificate_request
        ::CA::X509::CertificateRequest
      end

      def sign
        ::CA::X509::Sign
      end

      def issuer
        ::CA::X509::Issuer
      end
    end
  end
end
