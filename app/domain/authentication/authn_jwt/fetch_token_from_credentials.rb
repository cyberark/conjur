module Authentication
  module AuthnJwt

    class FetchTokenFromCredentials

      def fetch(authentication_parameters:)
        decoded_credentials(authentication_parameters).jwt
      end

      private

      def decoded_credentials(authentication_parameters)
        Authentication::Jwt::DecodedCredentials.new(authentication_parameters.credentials)
      end
    end
  end
end
