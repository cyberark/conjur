# frozen_string_literal: true

require 'command_class'

module Authentication

  Err = Errors::Authentication
  # Possible Errors Raised:
  # AuthenticatorNotFound, InvalidCredentials

  Login = CommandClass.new(
    dependencies: {
      validate_security:      ::Authentication::Security::ValidateSecurity.new,
      audit_event:            ::Authentication::AuditEvent.new,
      role_cls:               ::Role
    },
    inputs:       %i(authenticator_input authenticators enabled_authenticators)
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
      raise Err::AuthenticatorNotFound, @authenticator_input.authenticator_name unless authenticator
    end

    def validate_credentials
      raise Err::InvalidCredentials unless key
    end

    def validate_security
      @validate_security.(
        webservice: @authenticator_input.webservice,
          account: account,
          user_id: username,
          enabled_authenticators: @enabled_authenticators
      )
    end

    def audit_success
      @audit_event.(
        authenticator_input: @authenticator_input,
          success: true,
          message: nil
      )
    end

    def audit_failure(err)
      @audit_event.(
        authenticator_input: @authenticator_input,
          success: false,
          message: err.message
      )
    end

    def new_login
      LoginResponse.new(
        role_id:            role.id,
        authentication_key: key
      )
    end

    def role
      @role_cls.by_login(username, account: account)
    end

    def username
      @authenticator_input.username
    end

    def account
      @authenticator_input.account
    end
  end
end
