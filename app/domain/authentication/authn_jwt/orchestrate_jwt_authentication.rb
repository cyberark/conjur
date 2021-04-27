require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
module Authentication
  module AuthnJwt

    OrchestrateJwtAuthentication ||= CommandClass.new(
      dependencies: {
        token_factory: TokenFactory.new
      },
      inputs: %i[authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(
        :@authenticator_input, :account, :username
      )

      def call
        authenticate
      end

      private

      def authenticate
        @token_factory.signed_token(
          account: account,
          username: username
        )
      end
    end
  end
end
