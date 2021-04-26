module Authentication
  module AuthnJWT
    # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
    class JWTConfigurationInterface
      def get_identity; end;
      def validate_restrictions; end;
      def validate_and_decode; end;
    end
  end
end
