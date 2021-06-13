module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Factory that receives an authenticator name and returns the appropriate JWT vendor configuration class

      CreateVendorConfiguration ||= CommandClass.new(
        dependencies: {
          configuration_jwt_generic_vendor_class: ConfigurationJWTGenericVendor
        },
        inputs: %i[authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@authenticator_input, :authenticator_name)

        def call
          create_jwt_configuration
        end

        def create_jwt_configuration
          case authenticator_name
          when "authn-jwt"
            return @configuration_jwt_generic_vendor_class.new(@authenticator_input)
          else
            raise Errors::Authentication::AuthnJwt::UnsupportedAuthenticator, @authenticator_name
          end
        end
      end
    end
  end
end
