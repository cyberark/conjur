# frozen_string_literal: true

require 'command_class'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for signing a certificate request and returning the x.509 certificate
    class Sign
      extend CommandClass::Include

      command_class(
        dependencies: { env: ENV },
        inputs: %i(issuer certificate_request)
      ) do

        def call
          Certificate.new(certificate: signed_certificate)
        end

        private

        attr_reader :issuer, :certificate_request

        def signed_certificate
          Util::OpenSsl::X509::Certificate.from_hash(
            subject: subject,
            issuer: issuer.subject,
            public_key: certificate_request.csr.public_key,
            good_for: good_for,
            extensions: extensions
          ).tap do |cert|
            cert.sign(issuer.private_key, OpenSSL::Digest::SHA256.new)
          end
        end

        def extensions
          [
            ['basicConstraints', 'CA:FALSE', true],
            ['keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature', true],
            ['subjectKeyIdentifier', 'hash', false],
            ['subjectAltName',   subject_alt_names, false]
          ]
        end
  
        def good_for
          [ttl, issuer.max_ttl].min
        end

        def ttl
          certificate_request.ttl || issuer.max_ttl
        end
  
        def subject
          common_name = [
            requestor.account,
            issuer.issuer_id,
            requestor.kind,
            requestor.identifier
          ].join(':')
          OpenSSL::X509::Name.new [['CN', common_name]]
        end
  
        def subject_alt_names
          [
            "DNS:#{leaf_domain_name}",
            "URI:#{spiffe_id}"
          ].join(', ')
        end
  
        def leaf_domain_name
          requestor.identifier.split('/').last
        end

        def spiffe_id
          @spiffe_id ||= SpiffeId.new(issuer_id: issuer.issuer_id, requestor: requestor)
        end

        def requestor
          certificate_request.requestor
        end
      end
    end
  end
end
