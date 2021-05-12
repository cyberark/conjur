require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateAuthentication ||= CommandClass.new(
      dependencies: {
        uri_based_parameters_validator: Authentication::AuthnJwt::ValidateUriBasedParameters.new,
        jwt_configuration_factory: ConfigurationFactory.new,
        jwt_authenticator: Authentication::AuthnJwt::Authenticate.new,
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
        relevant_vendor = vendor
        @logger.debug(LogMessages::Authentication::AuthnJwt::ParsingIssuerFromUri.new(relevant_vendor))

        jwt_vendor_configuration = @jwt_configuration_factory.create_jwt_configuration(relevant_vendor)
        @jwt_authenticator.call(
          jwt_configuration: jwt_vendor_configuration,
          authenticator_input: @authenticator_input
        )
      end

      def vendor
        @authenticator_input.service_id
      end

      def validate_uri_based_parameters
        @uri_based_parameters_validator.call(
          authenticator_input: @authenticator_input,
          enabled_authenticators: @enabled_authenticators
        )
      end
    end
  end
end
