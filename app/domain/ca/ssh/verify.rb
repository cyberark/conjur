# frozen_string_literal: true

require 'command_class'

module CA
  module SSH
    # Responsible for verifying SSH certificate signing requests
    class Verify
      extend CommandClass::Include

      command_class(
        dependencies: { web_service: nil, env: ENV },
        inputs: %i(certificate_request)
      ) do

        def call
          verify_public_key
          verify_principals
        end

        private

        attr_reader :certificate_request

        def verify_public_key
          raise ArgumentError, "Request is missing public key for signing" unless certificate_request.params[:public_key].present?
        end
  
        def verify_principals
          raise ArgumentError, "Signing parameter 'principals' is missing." unless certificate_request.params[:principals].present?
        end
      end
    end
  end
end
