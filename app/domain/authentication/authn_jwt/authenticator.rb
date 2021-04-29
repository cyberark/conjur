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
        jwt_id
        validate_restrictions
        new_token
      end

      private

      def validate_and_decode_token
        decoded_token = @jwt_configuration.validate_and_decode_token(jwt_token: @authenticator_input.credentials)
        @authentication_parameters = Authentication::AuthnJwt::AuthenticationParameters.new(@authenticator_input, decoded_token)
      end

      def jwt_id
        # Will be changed when real get identity implemented
        @authentication_parameters.jwt_identity =  @jwt_configuration.jwt_id(@authentication_parameters)
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
