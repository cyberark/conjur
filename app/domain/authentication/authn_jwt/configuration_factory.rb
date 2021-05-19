module Authentication
  module AuthnJwt
    # Factory that receives an authenticator name and returns the appropriate JWT vendor configuration class
    class ConfigurationFactory
      AUTHENTICATORS = {
        "authn-jwt" => ConfigurationJWTGenericVendor
      }

      def create_jwt_configuration(authenticator_name)
        unless AUTHENTICATORS[authenticator_name]
          raise Errors::Authentication::AuthnJwt::UnsupportedAuthenticator, authenticator_name
        end

        AUTHENTICATORS[authenticator_name].new
      end
    end
  end
end
