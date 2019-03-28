# frozen_string_literal: true

require 'securerandom'
require 'command_class'

module CA
  module SSH
    # Signs an SSH public key
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
          Util::SSH::Certificate.from_hash(
            key_id: key_id,
            public_key: public_key,
            good_for: good_for,
            type: type,
            principals: principals,
            extensions: extensions
          ).tap do |cert|
            cert.sign!(issuer.private_key)
          end
        end

        def key_id
          role.id
        end

        def good_for
          [ttl, webservice.max_ttl].min
        end

        def type
          :user
        end

        def principals
          @principals ||= Array(certificate_request.params[:principals])
        end

        def extensions
          [
            ["permit-pty"]
          ]
        end

        def ttl
          ttl_data = certificate_request.params[:ttl]
          @ttl ||= if ttl_data.present?
            ISO8601::Duration.new(ttl_data).to_seconds 
          else
            webservice.max_ttl
          end
        end

        def role
          certificate_request.role
        end

        def issuer
          @issuer ||= Issuer.new(service: webservice)
        end

        def public_key
          case public_key_format
          when :pem
            Util::SSH::PublicKey.from_pem(public_key_data)
          when :openssh
            Util::SSH::PublicKey.from_openssh(public_key_data)
          else
            raise ArgumentError, "Invalid public key format: #{public_key_format}"
          end
        end

        def public_key_format
          @public_key_format ||= (@certificate_request.params[:public_key_format].presence || 'openssh').downcase.to_sym
        end

        def public_key_data
          @public_key_data ||= certificate_request.params[:public_key]
        end
      end
    end
  end
end
