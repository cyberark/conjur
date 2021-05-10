require 'command_class'

module Authentication
  module AuthnJwt

    ValidateInput ||= CommandClass.new(
      dependencies: {
        jwt_validate_body: Authentication::AuthnJwt::ValidateRequestBody.new
      },
      inputs: %i[authentication_parameters]
    ) do

      def call
        jwt_validate_body
      end

      private

      def jwt_validate_body
        @jwt_validate_body.(
          body_string: @authentication_parameters.credentials
        )
      end

    end
  end
end
