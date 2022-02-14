# frozen_string_literal: true

# Utility methods for Azure Authenticator
module AuthnAzureHelper

  SERVICE_ID = 'prod'
  ACCOUNT = 'cucumber'

  def create_and_set_azure_provider_uri_variable(value = azure_provider_uri)
    create_and_set_azure_variable("provider-uri", value)
  end

  def retrieve_user_assigned_azure_access_token
    retrieve_azure_access_token(retrieve_azure_token_command(is_user_assigned: true))
  end

  def retrieve_system_assigned_azure_access_token
    retrieve_azure_access_token(retrieve_azure_token_command(is_user_assigned: false))
  end

  def retrieve_azure_token_command is_user_assigned:
    base_command = "curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01" \
      "&resource=https%3A%2F%2Fmanagement.azure.com%2F"

    base_command = "#{base_command}&client_id=#{user_assigned_identity_client_id}" if is_user_assigned

    "#{base_command}' -H Metadata:true -s | jq -r '.access_token'"
  end

  def retrieve_azure_access_token retrieve_access_token_command
    @azure_token = run_command_in_machine(azure_machine_ip, azure_machine_username, azure_machine_password, retrieve_access_token_command)
  rescue => e
    raise "Failed to fetch azure token with reason: #{e}"
  end

  def authenticate_azure_token(service_id:, account:, username:, azure_token:, accept_encoding_header:)
    username = username.gsub("/", "%2F")
    path = "#{conjur_hostname}/authn-azure/#{service_id}/#{account}/#{username}/authenticate"

    payload = {}
    payload["jwt"] = azure_token

    headers["Accept-Encoding"] = accept_encoding_header

    post(path, payload)
  end

  private

  def create_and_set_azure_variable(variable_name, value)
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
    @azure_subscription_id ||= validated_env_var('AZURE_SUBSCRIPTION_ID')
  end

  def azure_resource_group
    @azure_resource_group ||= validated_env_var('AZURE_RESOURCE_GROUP')
  end

  def system_assigned_identity
    @system_assigned_identity ||= validated_env_var('SYSTEM_ASSIGNED_IDENTITY')
  end

  def user_assigned_identity
    @user_assigned_identity ||= validated_env_var('USER_ASSIGNED_IDENTITY')
  end

  def user_assigned_identity_client_id
    @user_assigned_identity_client_id ||= validated_env_var('USER_ASSIGNED_IDENTITY_CLIENT_ID')
  end

  def invalid_token
    "invalidAzureToken"
  end
end

World(AuthnAzureHelper)
