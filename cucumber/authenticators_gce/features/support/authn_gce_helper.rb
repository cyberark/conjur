module AuthnGceHelper
  include AuthenticatorHelpers

  # @todo Remove the env variables we the the vars will be injected
  # The ENV variables that are expected (temporary this will be injected)
  #
  # export GCE_INSTANCE_IP='104.198.201.199'
  # export GCE_INSTANCE_NAME='gcp-authn'
  # export GCE_INSTANCE_USERNAME='gcp-authn'
  # export GCE_PRIVATE_KEY_PATH=./.gcp-authn
  # export GCE_SERVICE_ACCOUNT_ID='108551114425891493254'
  # export GCE_SERVICE_ACCOUNT_EMAIL='120811889825-compute@developer.gserviceaccount.com'
  # export GCE_PROJECT_ID='refreshing-mark-284016'

  # Obtains a GCE identity token by running a curl command inside a GCE instance using ssh.
  # The above ENV variables are assumed to be set.
  # token_format; default="standard"
  # Specify whether or not the project and instance details are included in the identity token payload.
  # This flag only applies to Google Compute Engine instance identity tokens.
  # See https://cloud.google.com/compute/docs/instances/verifying-instance-identity#token_format
  # for more details on token format. TOKEN_FORMAT must be one of: standard, full.
  def gce_identity_access_token(audience:, token_format: 'standard')
    audience = audience.gsub("/", "%2F")

    @gce_identity_token = run_command_in_machine_with_private_key(
      machine_ip:        gce_instance_ip,
      machine_username:  gce_instance_user,
      private_key_path:  private_key_path,
      command:           identity_token_curl_cmd(audience, token_format))
  end

  def gce_instance_ip
    @gce_machine_ip ||= validated_env_var('GCE_INSTANCE_IP')
  end

  def gce_instance_name
    @gce_machine_name ||= validated_env_var('GCE_INSTANCE_NAME')
  end

  def gce_instance_user
    @gce_instance_user ||= validated_env_var('GCE_INSTANCE_USERNAME')
  end

  def private_key_path
    @private_key_path ||= validated_env_var('GCE_PRIVATE_KEY_PATH')
  end

  def gce_service_account_email
    @gce_service_account_email ||= validated_env_var('GCE_SERVICE_ACCOUNT_EMAIL')
  end

  def gce_project_id
    @gce_project_id ||= validated_env_var('GCE_PROJECT_ID')
  end

  def gce_service_account_id
    @gce_service_account_id ||= validated_env_var('GCE_SERVICE_ACCOUNT_ID')
  end

  def identity_token_curl_cmd(audience, token_format)
    header = 'Metadata-Flavor: Google'
    url = 'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity'
    query_string = "audience=#{audience}&format=#{token_format}"
    "curl -s -H '#{header}' '#{url}?#{query_string}'"
  end

  def authenticate_gce_token(account:, gce_token:)
    path_uri = "#{conjur_hostname}/authn-gce/#{account}/authenticate"

    payload = {}
    payload["jwt"] = gce_token

    post(path_uri, payload)
  end
end

World(AuthnGceHelper)
