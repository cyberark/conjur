require 'command_class'

module Authentication
  module AuthnJwt
    # Generic JWT authenticator that receive JWT vendor configuration and uses to validate that the authentication
    # request is valid, and return conjur authn token accordingly
    JwtAuthenticate ||= CommandClass.new(
      dependencies: {
        token_factory: TokenFactory.new
      },
      inputs: %i[jwt_configuration account username]
    ) do
      def call
        validate_and_decode
        get_identity
        validate_restrictions
        get_token
      end

      def get_identity
        # Will be changed when real get identity implemented
        unless @jwt_configuration.get_identity == "cucumber"
          raise "wrong identity"
        end
      end

      def validate_and_decode
        unless @jwt_configuration.validate_and_decode
          raise "validate and decode failed"
        end
      end

      def validate_restrictions
        unless @jwt_configuration.validate_restrictions
          raise "not matching policy annotations"
        end
      end

      def get_token
        @token_factory.signed_token(
          account: @account,
          username: @username
        )
      end
    end
  end
end
