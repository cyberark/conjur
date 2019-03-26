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
      validate_authenticator_exists

      validate_security

      validate_credentials

      audit_success

      new_login
    rescue => e
      audit_failure(e)
      raise e
    end

    private

    def authenticator
      @authenticator = @authenticators[@authenticator_input.authenticator_name]
    end

    def key
      @key = authenticator.login(@authenticator_input)
    end

    def validate_authenticator_exists
      raise AuthenticatorNotFound, @authenticator_input.authenticator_name unless authenticator
    end

    def validate_credentials
      raise InvalidCredentials unless key
    end

    def validate_security
      @validate_security.(input: @authenticator_input, enabled_authenticators: @enabled_authenticators)
    end

    def audit_success
      @audit_event.(input: @authenticator_input, success: true, message: nil)
    end

    def audit_failure(err)
      @audit_event.(input: @authenticator_input, success: false, message: err.message)
    end

    def new_login
      LoginResponse.new(
        role_id:            role(@authenticator_input.username, @authenticator_input.account).id,
        authentication_key: key
      )
    end

    def role(username, account)
      @get_role_by_login.(username: username, account: account)
    end
  end
end
