# frozen_string_literal: true

require 'command_class'
require 'authentication/webservices'

module Authentication

  Err ||= Errors::Authentication

  # Possible Errors Raised:
  # AuthenticatorNotFound, StatusNotImplemented, AccountNotDefined
  # WebserviceNotFound, RoleNotFound, RoleNotAuthorizedOnResource,
  # AuthenticatorNotWhitelisted

  ValidateStatus ||= CommandClass.new(
    dependencies: {
      validate_whitelisted_webservice: ::Authentication::Security::ValidateWhitelistedWebservice.new,
      validate_webservice_access:      ::Authentication::Security::ValidateWebserviceAccess.new,
      validate_webservice_exists:      ::Authentication::Security::ValidateWebserviceExists.new,
      role_class:                      ::Role,
      implemented_authenticators:      Authentication::InstalledAuthenticators.authenticators(ENV),
      audit_log:                       ::Audit.logger
    },
    inputs:       %i(authenticator_status_input enabled_authenticators)
  ) do

    extend Forwardable
    def_delegators :@authenticator_status_input, :authenticator_name, :account, :username, :webservice, :status_webservice, :role

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
      raise Err::AuthenticatorNotFound, authenticator_name unless authenticator
    end

    def validate_authenticator_implements_status_check
      raise Err::StatusNotImplemented, authenticator_name unless authenticator.class.method_defined?(:status)
    end

    def validate_user_has_access_to_status_webservice
      @validate_webservice_access.(
        webservice: status_webservice,
        account: account,
        user_id: username,
        privilege: 'read'
      )
    end

    def validate_webservice_is_whitelisted
      @validate_whitelisted_webservice.(
        webservice: webservice,
        account: account,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_authenticator_requirements
      authenticator.status(
        authenticator_status_input: @authenticator_status_input
      )
    end

    def validate_authenticator_webservice_exists
      @validate_webservice_exists.(
        webservice: webservice,
        account: account
      )
    end

    def audit_success
      @audit_log.log(
        ::Audit::Event::Authn::ValidateStatus.new(
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
        ::Audit::Event::Authn::ValidateStatus.new(
          authenticator_name: authenticator_name,
          service: webservice,
          role: role,
          success: false,
          error_message: err.message
        )
      )
    end

    def authenticator
      # The `@implemented_authenticators` map includes all authenticator classes that are implemented in
      # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.).

      @authenticator = @implemented_authenticators[authenticator_name]
    end
  end
end
