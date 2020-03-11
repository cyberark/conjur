# frozen_string_literal: true

# Utility methods for Azure authenticator

module AuthnAzureHelper
  include AuthenticatorHelpers

  def set_azure_provider_uri_variable(value = azure_provider_uri)
    set_azure_variable("provider-uri", value)
  end

  def retrieve_azure_access_token
    command = "curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s | jq -r '.access_token'"
    @azure_token = run_command_in_machine(azure_machine_ip, azure_machine_username, azure_machine_password, command)
  rescue Exception => err
    raise "Failed to fetch azure token with reason: #{err}"
  end

  def authenticate_azure_token(service_id:, account:, username:, azure_token: @azure_token)
    username = username.gsub("/", "%2F")
    path = "#{conjur_hostname}/authn-azure/#{service_id}/#{account}/#{username}/authenticate"

    payload = {}
    unless azure_token.nil?
      payload["jwt"] = azure_token
    end

    post(path, payload)
  end

  private

  def set_azure_variable(variable_name, value)
    path = "cucumber:variable:conjur/authn-azure/prod"
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

  def azure_provider_uri
    @azure_provider_uri ||= "https://sts.windows.net/#{validated_env_var('AZURE_TENANT_ID')}/"
  end

  def azure_machine_ip
    @azure_machine_ip ||= validated_env_var('AZURE_AUTHN_INSTANCE_IP')
  end

  def azure_machine_username
    @azure_machine_username ||= validated_env_var('AZURE_AUTHN_INSTANCE_USERNAME')
  end

  def azure_machine_password
    @azure_machine_password ||= validated_env_var('AZURE_AUTHN_INSTANCE_PASSWORD')
  end

  def azure_subscription_id
    @subscription_id ||= validated_env_var('AZURE_SUBSCRIPTION_ID')
  end

  def azure_resource_group
    @resource_group ||= validated_env_var('AZURE_RESOURCE_GROUP')
  end

  # TODO: add this once available
  #def system_assigned_identity
  #  @system_assigned_identity ||= validated_env_var('SYSTEM_ASSIGNED_IDENTITY')
  #end

  def user_assigned_identity
    @user_assigned_identity ||= validated_env_var('USER_ASSIGNED_IDENTITY')
  end
end

World(AuthnAzureHelper)
