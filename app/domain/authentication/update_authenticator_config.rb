require 'command_class'

module Authentication

  UpdateAuthenticatorConfig = CommandClass.new(
    dependencies: {
      webservice_class: ::Authentication::Webservice,
      resource_class: ::Resource,
      authenticator_config_class: ::AuthenticatorConfig
    },
    inputs: %i(account authenticator service_id enabled current_user)
  ) do
    
    def call
      validate_resource_visible

      validate_resource_writable

      update_authenticator_config
    end

    private

    def validate_resource_visible
      raise Exceptions::RecordNotFound, resource_id \
        unless resource.visible_to?(@current_user)
    end

    def validate_resource_writable
      raise ApplicationController::Forbidden \
        unless @current_user.allowed_to?(:write, resource)
    end

    def update_authenticator_config
      @authenticator_config_class
        .find_or_create(resource_id: resource_id)
        .update(enabled: @enabled)
    end
    
    def resource_id
      @resource_id ||= @webservice_class.new(
        account: @account,
        authenticator_name: @authenticator,
        service_id: @service_id
      ).resource_id
    end

    def resource
      @resource ||= Resource.with_pk!(resource_id)
    rescue Sequel::NoMatchingRow
      raise Exceptions::RecordNotFound, resource_id
    end
  end
end
