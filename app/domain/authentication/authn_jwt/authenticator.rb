require 'command_class'

module Authentication
  module AuthnJwt
    # Generic JWT authenticator that receive JWT vendor configuration and uses to validate that the authentication
    # request is valid, and return conjur authn token accordingly
    Authenticator = CommandClass.new(
      dependencies: {
        token_factory: TokenFactory.new,
        logger: Rails.logger
      },
      inputs: %i[jwt_configuration authenticator_input]
    ) do

      def call
        create_authentication_parameters
        validate_and_decode_token
        get_jwt_identity
        validate_restrictions
        new_token
      end

      private

      def create_authentication_parameters
        @logger.debug(LogMessages::Authentication::AuthnJwt::CREATING_AUTHENTICATION_PARAMETERS_OBJECT.new)
        @authentication_parameters = Authentication::AuthnJwt::AuthenticationParameters.new(@authenticator_input)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ExtractTokenString.new)
        @authentication_parameters.jwt_token = @jwt_configuration
                                                 .extract_token_from_credentials(
                                                   @authentication_parameters.credentials
                                                 )
      end

      def validate_and_decode_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::VALIDATE_AND_DECODE_TOKEN.new)
        @authentication_parameters.decoded_token = @jwt_configuration.validate_and_decode_token(@authentication_parameters)
      end

      def get_jwt_identity
        # Will be changed when real get identity implemented
        @logger.debug(LogMessages::Authentication::AuthnJwt::GET_JWT_IDENTITY.new)
        @authentication_parameters.jwt_identity =  @jwt_configuration.jwt_identity(@authentication_parameters)
      end

      def validate_restrictions
        @logger.debug(LogMessages::Authentication::AuthnJwt::CALLING_VALIDATE_RESTRICTIONS.new)
        @jwt_configuration.validate_restrictions(@authentication_parameters)
      end

      def new_token
        @logger.debug(LogMessages::Authentication::AuthnJwt::JWT_AUTHENTICATION_PASSED.new)
        @token_factory.signed_token(
          account: @authenticator_input.account,
          username: @authenticator_input.username
        )
      end
    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      def valid?(input)
        call(jwt_configuration:input[jwt_configuration] ,authenticator_input: input[autheticator_input])
      end

      def status(authenticator_status_input:)
        Authentication::AuthnJwt::ValidateStatus.new.call(
          authenticator_status_input: authenticator_status_input
        )
      end
    end
  end
end
