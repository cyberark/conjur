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
          vendor_configuration_class = AUTHENTICATORS[authenticator_name]

          unless vendor_configuration_class
            raise Errors::Authentication::AuthnJwt::UnsupportedAuthenticator, authenticator_name
          end

          vendor_configuration_class.new(authenticator_input)
        end
      end
    end
  end
end
