# frozen_string_literal: true

require 'command_class'

module Authentication

  ValidateStatus ||= CommandClass.new(
    dependencies: {
      validate_webservice_is_whitelisted:  ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
      validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
      validate_webservice_exists:          ::Authentication::Security::ValidateWebserviceExists.new,
      role_class:                          ::Role,
      implemented_authenticators:          Authentication::InstalledAuthenticators.authenticators(ENV),
      audit_log:                           ::Audit.logger
    },
    inputs:       %i(authenticator_status_input enabled_authenticators)
  ) do

    extend Forwardable
    def_delegators :@authenticator_status_input, :authenticator_name, :account,
                   :username, :webservice, :status_webservice, :role, :client_ip

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
      raise Errors::Authentication::AuthenticatorNotFound, authenticator_name unless authenticator
    end

    def validate_authenticator_implements_status_check
      unless authenticator.class.method_defined?(:status)
        raise Errors::Authentication::StatusNotImplemented, authenticator_name
      end
    end

    def validate_user_has_access_to_status_webservice
      @validate_role_can_access_webservice.(
        webservice: status_webservice,
        account: account,
        user_id: username,
        privilege: 'read'
      )
    end

    def validate_webservice_is_whitelisted
      @validate_webservice_is_whitelisted.(
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
          role_id: audit_role_id,
          client_ip: client_ip,
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
          role_id: audit_role_id,
          client_ip: client_ip,
          success: false,
          error_message: err.message
        )
      )
    end

    def audit_role_id
      ::Audit::Event::Authn::RoleId.new(
        role: role,
        account: @authenticator_status_input.account,
        username: @authenticator_status_input.username
      ).to_s
    end

    def authenticator
      # The `@implemented_authenticators` map includes all authenticator classes that are implemented in
      # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.).

      @authenticator = @implemented_authenticators[authenticator_name]
    end
  end
end
