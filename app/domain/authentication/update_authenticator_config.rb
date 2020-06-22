require 'command_class'

module Authentication

  UpdateAuthenticatorConfig = CommandClass.new(
    dependencies: {
      webservice_class:                     ::Authentication::Webservice,
      authenticator_config_class:           ::AuthenticatorConfig,
      validate_account_exists:              ::Authentication::Security::ValidateAccountExists.new,
      validate_webservice_exists:           ::Authentication::Security::ValidateWebserviceExists.new,
      validate_webservice_is_authenticator: ::Authentication::Security::ValidateWebserviceIsAuthenticator.new,
      validate_role_can_access_webservice:  ::Authentication::Security::ValidateRoleCanAccessWebservice.new
    },
    inputs:       %i(account authenticator_name service_id enabled username)
  ) do

    def call
      validate_account_exists
      validate_webservice_exists
      validate_webservice_is_authenticator
      validate_user_can_update_webservice
      update_authenticator_config
    end

    private

    def validate_account_exists
      @validate_account_exists.(
        account: @account
      )
    end

    def validate_webservice_exists
      @validate_webservice_exists.(
        webservice: webservice,
        account: @account
      )
    end

    def validate_webservice_is_authenticator
      @validate_webservice_is_authenticator.(
        webservice: webservice
      )
    end

    def validate_user_can_update_webservice
      @validate_role_can_access_webservice.(
        webservice: webservice,
        account: @account,
        user_id: @username,
        privilege: 'update'
      )
    end

    def update_authenticator_config
      @authenticator_config_class
        .find_or_create(resource_id: resource_id)
        .update(enabled: @enabled)
    end

    def webservice
      @webservice ||= @webservice_class.new(
        account:            @account,
        authenticator_name: @authenticator_name,
        service_id:         @service_id
      )
    end

    def resource_id
      @resource_id ||= webservice.resource_id
    end
  end
end
