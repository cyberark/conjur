module Authentication
  module AuthnJwt
    # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
    class JWTConfigurationDummyVendor < JWTConfigurationInterface
      def get_identity
        return "cucumber"
      end

      def validate_restrictions
        return true
      end

      def validate_and_decode
        return true
      end
    end
  end
end
