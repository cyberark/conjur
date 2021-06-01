module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Factory that receives an authenticator name and returns the appropriate JWT vendor configuration class
      class ConfigurationFactory
        AUTHENTICATORS = {
          "authn-jwt" => ConfigurationJWTGenericVendor
        }.freeze

        def create_jwt_configuration(authenticator_input)
          authenticator_name = authenticator_input.authenticator_name
          unless AUTHENTICATORS[authenticator_name]
            raise Errors::Authentication::AuthnJwt::UnsupportedAuthenticator, authenticator_name
          end

          AUTHENTICATORS[authenticator_name].new(authenticator_input)
        end
      end
    end
  end
end
