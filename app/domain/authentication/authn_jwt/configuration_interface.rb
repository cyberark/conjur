module Authentication
  module AuthnJwt
    # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
    class ConfigurationInterface
      def self.validate_input(authentication_parameters); end
      def self.jwt_identity(authentication_parameters); end
      def self.validate_restrictions(authentication_parameters); end
      def self.validate_and_decode_token(authentication_parameters); end
    end
  end
end
