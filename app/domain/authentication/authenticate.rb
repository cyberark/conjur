# frozen_string_literal: true

require 'command_class'
require 'authentication/authentication_common'

module Authentication
  Authenticate = CommandClass.new(
    dependencies: {
      validate_authenticator_exists: ::Authentication::ValidateAuthenticatorExist.new,
      validate_security: ::Authentication::ValidateSecurity.new,
      validate_origin: ::Authentication::ValidateOrigin.new,
      audit_event: ::Authentication::AuditEvent.new
    },
    inputs: %i(authenticator_input authenticators enabled_authenticators token_factory)
  ) do

    def call
      conjur_token(@authenticator_input)
    end

    private

    def conjur_token(input)
      authenticator = @authenticators[input.authenticator_name]

      @validate_authenticator_exists.(input: input, authenticator: authenticator)

      @validate_security.(input: input, enabled_authenticators: @enabled_authenticators)
      validate_credentials(input, authenticator)

      @validate_origin.(input: input)

      @audit_event.(
        input: input,
          success: true,
          message: nil
      )

      new_token(input)
    rescue => e
      @audit_event.(
        input: input,
          success: false,
          message: e.message
      )
      raise e
    end

    def validate_credentials(input, authenticator)
      raise ::Authentication::InvalidCredentials unless authenticator.valid?(input)
    end

    def new_token(input)
      @token_factory.signed_token(
        account: input.account,
        username: input.username
      )
    end
  end
end
