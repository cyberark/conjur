# frozen_string_literal: true

require 'command_class'

module Authentication
  Login = CommandClass.new(
    dependencies: {
      enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
      validate_security:      ::Authentication::ValidateSecurity.new,
      audit_event:            ::Authentication::AuditEvent.new,
      get_role_by_login:      GetRoleByLogin.new
    },
    inputs:       %i(authenticator_input authenticators)
  ) do

    def call
      login(@authenticator_input)
    end

    private

    def login(input)
      authenticator = @authenticators[input.authenticator_name]

      validate_authenticator_exists(input, authenticator)
      @validate_security.(input: input, enabled_authenticators: @enabled_authenticators)

      key = authenticator.login(input)
      raise InvalidCredentials unless key

      @audit_event.(input: input, success: true, message: nil)

      new_login(input, key)
    rescue => e
      @audit_event.(input: input, success: false, message: e.message)
      raise e
    end

    def new_login(input, key)
      LoginResponse.new(
        role_id:            role(input.username, input.account).id,
        authentication_key: key
      )
    end

    def role(username, account)
      @get_role_by_login.(username: username, account: account)
    end

    def validate_authenticator_exists(input, authenticator)
      raise AuthenticatorNotFound, input.authenticator_name unless authenticator
    end
  end
end
