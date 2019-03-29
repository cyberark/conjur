# frozen_string_literal: true

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for verifying signing requests for x.509 certificates
    class CertificateAuthority < ::CA::CertificateAuthority
      def verify_command
        ::CA::X509::Verify.new(webservice: webservice)
      end

      def sign_command
        ::CA::X509::Sign.new(webservice: webservice)
      end
    end
  end
end
