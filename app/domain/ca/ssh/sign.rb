# frozen_string_literal: true

require 'command_class'

module CA
  module SSH
    # Signs an SSH public key
    class Sign
      extend CommandClass::Include

      command_class(
        dependencies: { env: ENV },
        inputs: %i(issuer certificate_request)
      ) do

        def call
          Certificate.build(signed_certificate)
        end

        private

        attr_reader :certificate_request, :issuer

        def signed_certificate
          Util::SSH::Certificate.from_hash(
            key_id: key_id,
            public_key: certificate_request.public_key,
            good_for: good_for,
            type: type,
            principals: certificate_request.principals,
            extensions: extensions
          ).tap do |cert|
            cert.sign!(issuer.private_key)
          end
        end

        def key_id
          certificate_request.requested_by.id
        end

        def good_for
          [ttl, issuer.max_ttl].min
        end

        def type
          :user
        end

        def extensions
          [
            ["permit-pty"]
          ]
        end

        def ttl
          certificate_request.ttl || issuer.max_ttl
        end
      end
    end
  end
end
