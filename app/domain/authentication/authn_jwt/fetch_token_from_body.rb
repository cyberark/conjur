require 'command_class'

module Authentication
  module AuthnJwt

    FetchTokenFromBody ||= CommandClass.new(
      dependencies: {
      },
      inputs: %i[authentication_parameters]
    ) do

      def call
        read_body
        validate_body_is_jwt
      end

      private

      def read_body
        @authentication_parameters.credentials = @authentication_parameters.request.body.read
      end

      def validate_body_is_jwt
        @authentication_parameters.jwt_token = decoded_credentials.jwt
      end

      def decoded_credentials
        Authentication::Jwt::DecodedCredentials.new(@authentication_parameters.credentials)
      end
    end
  end
end
