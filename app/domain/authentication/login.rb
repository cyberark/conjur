# frozen_string_literal: true

require 'command_class'

module Authentication

  Err ||= Errors::Authentication
  # Possible Errors Raised:
  # AuthenticatorNotFound, InvalidCredentials

  Login ||= CommandClass.new(
    dependencies: {
      validate_security:      ::Authentication::Security::ValidateSecurity.new,
      log_audit_event:        ::Authentication::LogAuditEvent.new,
      role_cls:               ::Role
    },
    inputs:       %i(authenticator_input authenticators enabled_authenticators)
  ) do

    extend Forwardable
    def_delegators :@authenticator_input, :authenticator_name, :account,
                   :username, :webservice, :role, :origin

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
      @authenticator = @authenticators[authenticator_name]
    end

    def key
      @key = authenticator.login(@authenticator_input)
    end

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, authenticator_name unless authenticator
    end

    def validate_credentials
      raise Err::InvalidCredentials unless key
    end

    def validate_security
      @validate_security.(
        webservice: webservice,
        account: account,
        user_id: username,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def audit_success
      @log_audit_event.(
        event: ::Authentication::AuditEvent::Login,
        authenticator_name: authenticator_name,
        webservice: webservice,
        role: role,
        client_ip: origin,
        success: true,
        message: nil
      )
    end

    def audit_failure(err)
      @log_audit_event.(
        event: ::Authentication::AuditEvent::Login,
        authenticator_name: authenticator_name,
        webservice: webservice,
        role: role,
        client_ip: origin,
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
  end
end
