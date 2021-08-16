require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateAuthentication ||= CommandClass.new(
      dependencies: {
        validate_uri_based_parameters: Authentication::AuthnJwt::InputValidation::ValidateUriBasedParameters.new,
        create_vendor_configuration: Authentication::AuthnJwt::VendorConfigurations::CreateVendorConfiguration.new,
        jwt_authenticator: Authentication::AuthnJwt::Authenticator.new,
        logger: Rails.logger
      },
      inputs: %i[authenticator_input enabled_authenticators]
    ) do
      def call
        validate_uri_based_parameters
        authenticate_jwt
      end

      private

      def validate_uri_based_parameters
        @validate_uri_based_parameters.call(
          authenticator_input: @authenticator_input,
          enabled_authenticators: @enabled_authenticators
        )
      end

      def authenticate_jwt
        @logger.info(LogMessages::Authentication::AuthnJwt::JwtAuthenticatorEntryPoint.new(@authenticator_input.authenticator_name))

        @jwt_authenticator.call(
          vendor_configuration: vendor_configuration,
          authenticator_input: @authenticator_input
        )
      end

      def vendor_configuration
        @vendor_configuration ||= @create_vendor_configuration.call(
          authenticator_input: @authenticator_input
        )
      end
    end
  end
end
