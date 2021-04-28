module Authentication
  module AuthnJwt
    # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
    class JWTConfigurationDummyVendor < JWTConfigurationInterface
      def self.conjur_id
        "cucumber"
      end

      def self.validate_restrictions
        true
      end

      def self.validate_and_decode_token(jwt_token)
        true
      end
    end
  end
end
