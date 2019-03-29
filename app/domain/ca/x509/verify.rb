# frozen_string_literal: true

require 'command_class'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for verifying x.509 certificate signing requests
    class Verify
      extend CommandClass::Include

      command_class(
        dependencies: { web_service: nil, env: ENV },
        inputs: %i(certificate_request)
      ) do

        def call
          verify_role_is_host
          verify_csr_presence
          verify_csr_public_key
        end

        private

        attr_reader :certificate_request

        def verify_role_is_host
          raise ArgumentError, "Requestor is not a host." unless certificate_request.role.kind == 'host'
        end

        def verify_csr_presence
          raise ArgumentError, "Signing parameter 'csr' is missing." unless certificate_request.params[:csr].present?
        end

        def verify_csr_public_key
          raise ::Exceptions::Forbidden, 'CSR cannot be verified' unless csr.verify(csr.public_key)
        end

        def csr
          @csr ||= OpenSSL::X509::Request.new(certificate_request.params[:csr])
        end
      end
    end
  end
end
