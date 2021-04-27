require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateJwtAuthentication ||= CommandClass.new(
      dependencies: {
        jwt_configuration_factory: JwtConfigurationFactory.new
      },
      inputs: %i[authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(
        :@authenticator_input, :account, :username
      )

      def call
        authenticate_jwt
      end

      private

      def get_vendor
        "dummy"
      end

      def authenticate_jwt
        JwtAuthenticate.new.(
          jwt_configuration: @jwt_configuration_factory.get_jwt_configuration(get_vendor),
          account: account,
          username: username
        )
      end
    end
  end
end
