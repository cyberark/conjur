# frozen_string_literal: true

module CA
  module SSH
    # Represents a signed SSH certificate
    class Certificate < Dry::Struct::Value
      def self.build(certificate)
        Certificate.new(
          ssh_type: certificate.ssh_type,
          blob: certificate.to_blob
        )
      end

      attribute :ssh_type, Types::Strict::String
      attribute :blob, Types::Strict::String

      def to_formatted
        FormattedCertificate.new(content: cert_contents, content_type: 'application/x-openssh-file')
      end

      private

      def cert_contents
        "#{ssh_type} #{Base64.strict_encode64(blob)}"
      end
    end
  end
end
