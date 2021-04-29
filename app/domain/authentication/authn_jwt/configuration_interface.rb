module Authentication
  module AuthnJwt
    # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
    class ConfigurationInterface
      def self.jwt_id(authentication_parameters); end
      def self.validate_restrictions; end
      def self.validate_and_decode_token(jwt_token); end
    end
  end
end
