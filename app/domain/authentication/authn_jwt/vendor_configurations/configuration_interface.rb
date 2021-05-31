module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Interface containing JWT configuration functions to be implemented in JWTConfiguration class for a vendor
      class ConfigurationInterface
        def authentication_parameters(authenticator_input); end

        def jwt_identity; end

        def validate_restrictions; end

        def validate_and_decode_token; end
      end
    end
  end
end
