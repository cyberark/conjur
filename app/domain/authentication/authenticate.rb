# frozen_string_literal: true

require 'command_class'
require 'authentication/validate_security'

module Authentication

  Err ||= Errors::Authentication
  # Possible Errors Raised:
  # AuthenticatorNotFound, InvalidCredentials

  Authenticate ||= CommandClass.new(
    dependencies: {
      token_factory:     TokenFactory.new,
      validate_security: ::Authentication::Security::ValidateSecurity.new,
      validate_origin:   ::Authentication::ValidateOrigin.new,
      audit_log:         ::Audit.logger
    },
    inputs:       %i(authenticator_input authenticators enabled_authenticators)
  ) do

    extend Forwardable
    def_delegators(
      :@authenticator_input, :authenticator_name, :account, :username,
      :webservice, :origin, :role
    )

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
      @authenticator = @authenticators[authenticator_name]
    end

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, authenticator_name unless authenticator
    end

    def validate_credentials
      raise Err::InvalidCredentials unless authenticator.valid?(@authenticator_input)
    end

    def validate_security
      @validate_security.(
        webservice: webservice,
        account: account,
        user_id: username,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_origin
      @validate_origin.(
        account: account,
        username: username,
        origin: origin
      )
    end

    def audit_success
      @audit_log.log(
        ::Audit::Event::Authn::Authenticate.new(
          authenticator_name: authenticator_name,
          service: webservice,
          role: role,
          success: true,
          error_message: nil
        )
      )
    end

    def audit_failure(err)
      @audit_log.log(
        ::Audit::Event::Authn::Authenticate.new(
          authenticator_name: authenticator_name,
          service: webservice,
          role: role,
          success: false,
          error_message: err.message
        )
      )
    end

    def new_token
      @token_factory.signed_token(
        account:  account,
        username: username
      )
    end

  end
end
