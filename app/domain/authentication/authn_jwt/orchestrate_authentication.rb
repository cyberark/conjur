require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateAuthentication ||= CommandClass.new(
      dependencies: {
        validate_uri_based_parameters: Authentication::AuthnJwt::InputValidation::ValidateUriBasedParameters.new,
        configuration_factory: Authentication::AuthnJwt::VendorConfigurations::CreateVendorConfiguration.new,
        jwt_authenticator: Authentication::AuthnJwt::Authenticator.new,
        logger: Rails.logger,
        installed_authenticators_class: Authentication::InstalledAuthenticators
      },
      inputs: %i[authenticator_input]
    ) do

      def call
        validate_uri_based_parameters
        authenticate_jwt
      end

      private

      def validate_uri_based_parameters
        @validate_uri_based_parameters.call(
          authenticator_input: @authenticator_input,
          enabled_authenticators: @installed_authenticators_class.enabled_authenticators_str
        )
      end

      def authenticate_jwt
        @logger.info(LogMessages::Authentication::AuthnJwt::JwtAuthenticatorEntryPoint.new(relevant_authenticator))

        jwt_authenticator_configuration = @configuration_factory.call(
          authenticator_input: @authenticator_input
        )
        @jwt_authenticator.call(
          jwt_configuration: jwt_authenticator_configuration,
          authenticator_input: @authenticator_input
        )
      end

      def relevant_authenticator
        @relevant_authenticator ||= @authenticator_input.authenticator_name
      end
    end
  end
end
