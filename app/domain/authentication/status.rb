# frozen_string_literal: true

require 'command_class'
require 'authentication/webservices'

module Authentication

  Err = Errors::Authentication

  # Possible Errors Raised:
  # TODO: add errors

  Status = CommandClass.new(
    dependencies: {
      role_class: ::Role,
      resource_class: ::Resource,
      webservices_class: ::Authentication::Webservices,
      implemented_authenticators: Authentication::InstalledAuthenticators.authenticators(ENV),
      enabled_authenticators: ENV['CONJUR_AUTHENTICATORS']
    },
    inputs: %i(authenticator_name account authenticator_webservice user_id)
  ) do

    def call
      validate_authenticator_exists
      validate_authenticator_implements_status_check

      validate_account_exists

      validate_user_has_access_to_status_route

      validate_authenticator_webservice_exists
      validate_webservice_is_whitelisted

      validate_authenticator_requirements

        # todo: audit success

        # todo: create response object
    rescue => e
      # todo: audit failure
      raise e
    end

    private

    def validate_authenticator_exists
      raise Err::AuthenticatorNotFound, @authenticator_name unless authenticator
    end

    def validate_authenticator_implements_status_check
      raise Err::StatusNotImplemented, @authenticator_name unless authenticator.method_defined?(:status)
    end

    def validate_account_exists
      raise Err::Security::AccountNotDefined, @account unless account_admin_role
    end

    def validate_user_has_access_to_status_route
      validate_status_webservice_exists
      validate_user_is_defined
      validate_user_has_access
    end

    def validate_status_webservice_exists
      validate_webservice_exists(status_webservice)
    end

    def validate_authenticator_webservice_exists
      validate_webservice_exists(@authenticator_webservice)
    end

    def validate_webservice_exists(webservice)
      raise Err::Security::ServiceNotDefined, webservice.name unless webservice_resource(webservice)
    end

    def validate_user_is_defined
      raise Err::Security::UserNotDefinedInConjur, @user_id unless user_role
    end

    def validate_user_has_access
      # Ensure user has access to the service
      raise Err::Security::UserNotAuthorizedInConjur,
            @user_id unless user_role.allowed_to?('read', webservice_resource(status_webservice))
    end

    def validate_webservice_is_whitelisted
      is_whitelisted = whitelisted_webservices.include?(@authenticator_webservice)
      raise Err::Security::NotWhitelisted, @authenticator_webservice.name unless is_whitelisted
    end

    def validate_authenticator_requirements
      authenticator.status
    end

    def authenticator
      # The `@implemented_authenticators` map includes all authenticator classes that are implemented in
      # Conjur (`Authentication::AuthnOidc::Authenticator`, `Authentication::AuthnLdap::Authenticator`, etc.).

      @authenticator = @implemented_authenticators[@authenticator_name]
    end

    def account_admin_role
      @account_admin_role ||= @role_class["#{@account}:user:admin"]
    end

    def status_webservice
      @authenticator_webservice.status_webservice
    end

    def webservice_resource(webservice)
      @resource_class[webservice.resource_id]
    end

    def authenticator_webservice_resource
      @resource_class[authenticator_webservice_resource_id]
    end

    def authenticator_webservice_resource_id
      @authenticator_webservice.resource_id
    end

    def user_role
      @user_role ||= @role_class[user_role_id]
    end

    def user_role_id
      @user_role_id ||= @role_class.roleid_from_username(@account, @user_id)
    end

    def whitelisted_webservices
      @webservices_class.from_string(
        @account,
        @enabled_authenticators || Authentication::Common.default_authenticator_name
      )
    end
  end
end
