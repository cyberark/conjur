module Authentication
  module AuthnJwt
    # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
    class ConfigurationInterface
      def create_authentication_parameters(authenticator_input); end
      def jwt_identity(authentication_parameters); end
      def validate_restrictions(authentication_parameters); end
      def validate_and_decode_token(authentication_parameters); end
    end
  end
end
