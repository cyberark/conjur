require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateJwtAuthentication ||= CommandClass.new(
      dependencies: {
        jwt_configuration_factory: JwtConfigurationFactory.new,
        jwt_authenticator: Authentication::AuthnJwt::Authenticate.new
      },
      inputs: %i[authenticator_input]
    ) do

      def call
        authenticate_jwt
      end

      private

      def authenticate_jwt
        jwt_vendor_configuration = @jwt_configuration_factory.create_jwt_configuration(vendor)
        @jwt_authenticator.call(
          jwt_configuration: jwt_vendor_configuration,
          authenticator_input: @authenticator_input
        )
      end

      def vendor
        @authenticator_input.service_id
      end
    end
  end
end
