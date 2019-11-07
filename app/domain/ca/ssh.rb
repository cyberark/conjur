module CA
  # Provides helper methods for creating the SSH
  # value and command objects for certificate signing.
  module SSH
    class << self
      def certificate_request
        ::CA::SSH::CertificateRequest
      end

      def sign
        ::CA::SSH::Sign
      end

      def issuer
        ::CA::SSH::Issuer
      end
    end
  end
end
