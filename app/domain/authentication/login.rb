# frozen_string_literal: true

require 'command_class'

module Authentication

  Login ||= CommandClass.new(
    dependencies: {
      validate_webservice_is_whitelisted:
        ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
      validate_role_can_access_webservice:
        ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
      audit_log: ::Audit.logger,
      role_cls: ::Role
    },
    inputs: %i[authenticator_input authenticators enabled_authenticators]
  ) do
    extend(Forwardable)
    def_delegators(
      :@authenticator_input, :authenticator_name, :account, :username,
      :webservice, :role, :client_ip
    )

    def call
      validate_authenticator_exists
      validate_webservice_is_whitelisted
      validate_user_has_access_to_webservice
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
      @key ||= authenticator.login(@authenticator_input)
    end

    def validate_authenticator_exists
      raise Errors::Authentication::AuthenticatorNotSupported, authenticator_name unless authenticator
    end

    def validate_credentials
      raise Errors::Authentication::InvalidCredentials unless key
    end

    def validate_webservice_is_whitelisted
      @validate_webservice_is_whitelisted.(
        webservice: webservice,
        account: account,
        enabled_authenticators: @enabled_authenticators
      )
    end

    def validate_user_has_access_to_webservice
      @validate_role_can_access_webservice.(
        webservice: webservice,
        account: account,
        user_id: username,
        privilege: 'authenticate'
      )
    end

    def audit_success
      @audit_log.log(
        ::Audit::Event::Authn::Login.new(
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
        ::Audit::Event::Authn::Login.new(
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
        role: role, account: account, username: username
      ).to_s
    end

    def new_login
      LoginResponse.new(
        role_id: role.id,
        authentication_key: key
      )
    end

    def role
      @role_cls.by_login(username, account: account)
    end
  end
end
