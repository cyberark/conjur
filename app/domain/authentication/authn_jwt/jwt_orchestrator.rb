require 'command_class'

# This class is the starting point of the JWT authenticate requests, responsible to identify the vendor configuration and to run the JWT authenticator
class JWTOrchestrator
  module AuthnJwt

    Authenticate ||= CommandClass.new(
    dependencies: {},
    inputs: %i[authenticator_input]
  ) do
      def call
        authenticate
      end

      private

      def authenticate
        "Jwt Orechestrator works!"
      end
    end
  end
end
