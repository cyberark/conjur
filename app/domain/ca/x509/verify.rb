# frozen_string_literal: true

require 'command_class'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for verifying x.509 certificate signing requests
    class Verify
      extend CommandClass::Include

      command_class(
        dependencies: { webservice: nil, env: ENV },
        inputs: %i(certificate_request)
      ) do

        def call
          verify_role_is_host

          verify_csr_presence
          verify_csr_public_key

          verify_use
        end

        private

        attr_reader :certificate_request, :webservice

        def verify_role_is_host
          raise ArgumentError, "Requestor is not a host." unless certificate_request.role.kind == 'host'
        end

        def verify_csr_presence
          raise ArgumentError, "Signing parameter 'csr' is missing." unless certificate_request.params[:csr].present?
        end

        def verify_csr_public_key
          raise ::Exceptions::Forbidden, 'CSR cannot be verified' unless csr.verify(csr.public_key)
        end

        DEFAULT_USE_PERMISSIONS = {
          server: 'true',
          client: 'true',
          ca: 'false'
        }.freeze

        def verify_use
          # Verify use exists
          unless %i(server client ca).include?(use)
            raise ArgumentError, "Signing parameter 'use' is invalid. Must be 'server', 'client', or 'ca'." 
          end

          # Verify role may request use
          unless (role_config("#{use}-use-permitted").presence || DEFAULT_USE_PERMISSIONS[use]) == "true"
            raise ::Exceptions::Forbidden, "Role not permitted to request certificate use: '#{use}'."
          end

          # Verify CA may issue use
          unless (webservice_config("#{use}-use-permitted").presence || DEFAULT_USE_PERMISSIONS[use]) == "true"
            raise ::Exceptions::Forbidden, "CA not permitted to issue certificate use: '#{use}'."
          end
        end

        def csr
          @csr ||= OpenSSL::X509::Request.new(certificate_request.params[:csr])
        end

        def use
          @use ||= certificate_request.params.fetch(:use, 'server').downcase.to_sym
        end

        def role_config(name)
          # Service specific config
          role_resource.annotation("ca/#{webservice.service_id}/#{name}") ||
            # Fallback to global config
            role_resource.annotation("ca/#{name}")
        end

        def role_resource
          @role_resource ||= certificate_request.role.resource
        end

        def webservice_config(name)
          webservice.resource.annotation("ca/#{name}")
        end
      end
    end
  end
end
