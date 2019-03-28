# frozen_string_literal: true

module CA
  module SSH
    # Responsible for signing requests for x.509 certificates
    class CertificateAuthority < ::CA::CertificateAuthority
      def verify_command
        Verify.new(webservice: webservice)
      end

      def sign_command
        Sign.new(webservice: webservice)
      end
    end
  end
end
