# frozen_string_literal: true

module CA
  module SSH
    # Represents a signed SSH certificate
    class Certificate < Dry::Struct
      attribute :certificate, Types.Definition(Net::SSH::Authentication::Certificate)

      def to_formatted
        FormattedCertificate.new(content: cert_contents, content_type: 'application/x-openssh-file')
      end

      private

      def cert_contents
        "#{certificate.ssh_type} #{Base64.strict_encode64(certificate.to_blob)}"
      end
    end
  end
end
