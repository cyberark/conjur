require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateAuthentication ||= CommandClass.new(
      dependencies: {
        validate_uri_based_parameters: Authentication::AuthnJwt::ValidateUriBasedParameters.new,
        jwt_configuration_factory: ConfigurationFactory.new,
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

      def authenticate_jwt
        relevant_authenticator = authenticator_name
        @logger.debug(LogMessages::Authentication::AuthnJwt::JWTAuthenticatorEntryPoint.new(relevant_authenticator))

        jwt_authenticator_configuration = @jwt_configuration_factory.create_jwt_configuration(relevant_authenticator)
        @jwt_authenticator.call(
          jwt_configuration: jwt_authenticator_configuration,
          authenticator_input: @authenticator_input
        )
      end

      def authenticator_name
        @authenticator_input.authenticator_name
      end

      def validate_uri_based_parameters
        @validate_uri_based_parameters.call(
          authenticator_input: @authenticator_input,
          enabled_authenticators: @enabled_authenticators
        )
      end
    end
  end
end
