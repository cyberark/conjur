require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateAuthentication ||= CommandClass.new(
      dependencies: {
        jwt_configuration_factory: ConfigurationFactory.new,
        jwt_authenticator: Authentication::AuthnJwt::Authenticate.new,
        logger: Rails.logger
      },
      inputs: %i[authenticator_input]
    ) do

      def call
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
    end
  end
end
