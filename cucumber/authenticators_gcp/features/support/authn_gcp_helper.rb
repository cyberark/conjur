module AuthnGcpHelper
  include AuthenticatorHelpers

  # The ENV variables that are expected (temporary this will be injected)
  #
  # export GCE_INSTANCE_IP='104.198.201.199'
  # export GCE_INSTANCE_USERNAME='gcp-authn'
  # export GCE_PRIVATE_KEY_PATH=./.gcp-authn
  # export GCP_SERVICE_ACCOUNT_ID='108551114425891493254'


  # Obtains a GCE identity token by running a curl command inside a GCE instance using ssh.
  # The above ENV variables are assumed to be set.
  # token_format; default="standard"
  # Specify whether or not the project and instance details are included in the identity token payload.
  # This flag only applies to Google Compute Engine instance identity tokens.
  # See https://cloud.google.com/compute/docs/instances/verifying-instance-identity#token_format
  # for more details on token format. TOKEN_FORMAT must be one of: standard, full.
  def gce_identity_access_token(audience:, token_format: 'standard')
    @gce_identity_token = run_command_in_machine_with_private_key(
      gce_instance_ip,
      gce_instance_user,
      private_key_path,
      identity_token_curl_cmd(audience, token_format))
  end

  def gce_instance_ip
    @gce_machine_ip ||= validated_env_var('GCE_INSTANCE_IP')
  end

  def gce_instance_user
    @gce_instance_user ||= validated_env_var('GCE_INSTANCE_USERNAME')
  end

  def private_key_path
    @private_key_path ||= validated_env_var('GCE_PRIVATE_KEY_PATH')
  end

  def identity_token_curl_cmd(audience, token_format)
    header = 'Metadata-Flavor: Google'
    url = 'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity'
    query_string = "audience=#{audience}&format=#{token_format}"
    "curl -s -H '#{header}' '#{url}?#{query_string}'"
  end

  def gcp_service_account_id
    @gcp_service_account_id ||= validated_env_var('GCP_SERVICE_ACCOUNT_ID')
  end

  def authenticate_gcp_token(account:, username:, azure_token:)
    username = username.gsub("/", "%2F")
    path = "#{conjur_hostname}/authn-gcp/#{account}/#{username}/authenticate"

    payload = {}
    payload["jwt"] = azure_token

    post(path, payload)
  end
end

World(AuthnGcpHelper)
