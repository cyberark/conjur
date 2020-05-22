# frozen_string_literal: true

require 'command_class'
require 'authentication/validate_security'

module Authentication

  Err ||= Errors::Authentication
  # Possible Errors Raised:
  # AuthenticatorNotFound, InvalidCredentials

  Authenticate ||= CommandClass.new(
    dependencies: {
      token_factory:          TokenFactory.new,
      validate_security:      ::Authentication::Security::ValidateSecurity.new,
      validate_origin:        ::Authentication::ValidateOrigin.new,
      log_audit_event:        ::Authentication::LogAuditEvent.new
    },
    inputs:       %i(authenticator_input authenticators enabled_authenticators)
  ) do

    def call
      validate_authenticator_exists
      validate_security
      validate_origin
      validate_credentials
      audit_success
      new_token
    rescue => e
      audit_failure(e)
      raise e
    end

    private

    def authenticator
      @authenticator = @authenticators[@authenticator_input.authenticator_name]
    end

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, @authenticator_input.authenticator_name unless authenticator
    end

    def validate_credentials
      raise Err::InvalidCredentials unless authenticator.valid?(@authenticator_input)
    end

    def validate_security
      @validate_security.(
        webservice: @authenticator_input.webservice,
        account: @authenticator_input.account,
        user_id: @authenticator_input.username,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_origin
      @validate_origin.(input: @authenticator_input)
    end

    def audit_success
      @log_audit_event.(
        event: ::Authentication::AuditEvent::Authenticate,
        authenticator_input: @authenticator_input,
        success: true,
        message: nil
      )
    end

    def audit_failure(err)
      @log_audit_event.(
        event: ::Authentication::AuditEvent::Authenticate,
        authenticator_input: @authenticator_input,
        success: false,
        message: err.message
      )
    end

    def new_token
      @token_factory.signed_token(
        account:  @authenticator_input.account,
        username: @authenticator_input.username
      )
    end

  end
end
