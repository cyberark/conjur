module Authentication
  module AuthnJwt

    FetchTokenFromCredentials ||= CommandClass.new(
      dependencies: {
        decoded_credentials_class: Authentication::Jwt::DecodedCredentials
      },
      inputs: %i[authentication_parameters]
    ) do

      def call
        decoded_credentials(@authentication_parameters).jwt
      end

      private

      def decoded_credentials(authentication_parameters)
        @decoded_credentials_class.new(authentication_parameters.credentials)
      end
    end
  end
end
