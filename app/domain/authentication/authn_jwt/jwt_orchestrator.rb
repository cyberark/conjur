require 'command_class'

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