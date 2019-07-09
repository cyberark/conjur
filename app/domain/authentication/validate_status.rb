# frozen_string_literal: true

require 'command_class'
require 'authentication/webservices'

module Authentication

  Err = Errors::Authentication

  # Possible Errors Raised:
  # AuthenticatorNotFound, StatusNotImplemented, AccountNotDefined
  # ServiceNotDefined, UserNotDefinedInConjur, UserNotAuthorizedInConjur,
  # NotWhitelisted

  ValidateStatus = CommandClass.new(
    dependencies: {
      validate_whitelisted_webservice: ::Authentication::Security::ValidateWhitelistedWebservice.new,
      validate_webservice_access: ::Authentication::Security::ValidateWebserviceAccess.new,
      validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
      role_class: ::Role,
      implemented_authenticators: Authentication::InstalledAuthenticators.authenticators(ENV),
      enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
      audit_event: AuditEvent.new
    },
    inputs: %i(authenticator_name account status_webservice user)
  ) do

    def call
      validate_authenticator_exists
      validate_authenticator_implements_status_check

      validate_user_has_access_to_status_webservice

      validate_authenticator_webservice_exists
      validate_webservice_is_whitelisted

      validate_authenticator_requirements

      audit_success
    rescue => e
      audit_failure(e)
      raise e
    end

    private

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, @authenticator_name unless authenticator
    end

    def validate_authenticator_implements_status_check
      raise Err::StatusNotImplemented, @authenticator_name unless authenticator.class.method_defined?(:status)
    end

    def validate_user_has_access_to_status_webservice
      @validate_webservice_access.(
        webservice: @status_webservice,
          account: @account,
          user_id: user_id,
          privilege: 'read'
      )
    end

    def validate_webservice_is_whitelisted
      @validate_whitelisted_webservice.(
        webservice: authenticator_webservice,
          account: @account,
          enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_authenticator_requirements
      authenticator.status(
        account: @account,
        authenticator_name: @authenticator_name,
        webservice: authenticator_webservice
      )
    end

    def validate_authenticator_webservice_exists
      @validate_webservice_exists.(
        webservice: authenticator_webservice,
          account: @account
      )
    end

    def audit_success
      @audit_event.(
        resource_id: authenticator_webservice.resource_id,
          authenticator_name: @authenticator_name,
          account: @account,
          username: user_id,
          success: true,
          message: nil
      )
    end

    def audit_failure(err)
      @audit_event.(
        resource_id: authenticator_webservice.resource_id,
          authenticator_name: @authenticator_name,
          account: @account,
          username: user_id,
          success: false,
          message: err.message
      )
    end

    def authenticator
      # The `@implemented_authenticators` map includes all authenticator classes that are implemented in
      # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.).

      @authenticator = @implemented_authenticators[@authenticator_name]
    end

    def authenticator_webservice
      @status_webservice.parent_webservice
    end

    def user_id
      @user_id ||= @role_class.username_from_roleid(@user.role_id)
    end
  end
end
