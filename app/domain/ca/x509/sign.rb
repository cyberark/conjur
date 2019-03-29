# frozen_string_literal: true

require 'command_class'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for signing a certificate request and returning the x.509 certificate
    class Sign
      extend CommandClass::Include

      command_class(
        dependencies: { webservice: nil, env: ENV },
        inputs: %i(certificate_request)
      ) do

        def call
          Certificate.new(certificate: signed_certificate)
        end

        private

        attr_reader :certificate_request, :webservice

        def signed_certificate          
          Util::OpenSsl::X509::Certificate.from_hash(
            subject: subject,
            issuer: issuer.subject,
            public_key: csr.public_key,
            good_for: good_for,
            extensions: extensions
          ).tap do |cert|
            cert.sign(issuer.private_key, OpenSSL::Digest::SHA256.new)
          end
        end

        def csr
          @csr ||= ::Util::OpenSsl::X509::SmartCsr.new(certificate_request.params[:csr])
        end

        def issuer
          @issuer ||= ::CA::X509::Issuer.new(service: webservice)
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
          [ttl, webservice.max_ttl].min
        end

        def ttl
          ttl_data = certificate_request.params[:ttl]
          @ttl ||= if ttl_data.present?
            ISO8601::Duration.new(ttl_data).to_seconds 
          else
            webservice.max_ttl
          end
        end
  
        def subject
          common_name = [
            role.account,
            webservice.service_id,
            role.kind,
            role.identifier
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
          role.identifier.split('/').last
        end

        def spiffe_id
          @spiffe_id ||= SpiffeId.new(issuer_id: webservice.service_id, role: role)
        end

        def role
          certificate_request.role
        end
      end
    end
  end
end
