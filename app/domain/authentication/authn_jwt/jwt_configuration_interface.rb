module Authentication
  module AuthnJwt
    # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
    class JWTConfigurationInterface
      def self.conjur_id; end
      def self.validate_restrictions; end
      def self.validate_and_decode_token(jwt_token); end
    end
  end
end
