require 'command_class'

module Authentication
  module AuthnJwt
    # Generic JWT authenticator that receive JWT vendor configuration and uses to validate that the authentication
    # request is valid, and return conjur authn token accordingly
    Authenticate = CommandClass.new(
      dependencies: {
        token_factory: TokenFactory.new
      },
      inputs: %i[jwt_configuration authenticator_input]
    ) do

      def call
        validate_and_decode_token
        conjur_id
        validate_restrictions
        new_token
      end

      private

      def validate_and_decode_token
        #TODO : Need to decide how the token is going to be given and parsed and change this line according to this
        unless @jwt_configuration.validate_and_decode_token(jwt_token: @authenticator_input.credentials)
          raise "validate and decode failed"
        end
      end

      def conjur_id
        # Will be changed when real get identity implemented
        @jwt_configuration.conjur_id
      end

      def validate_restrictions
        unless @jwt_configuration.validate_restrictions
          raise "not matching policy annotations"
        end
      end

      def new_token
        @token_factory.signed_token(
          account: @authenticator_input.account,
          username: @authenticator_input.username
        )
      end
    end
  end
end
