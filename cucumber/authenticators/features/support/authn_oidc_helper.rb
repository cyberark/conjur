

module AuthnOidcHelper
  include AuthenticatorHelpers

  def authenticate_id_token_with_oidc(service_id:, account:)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"
    payload = { id_token: "{\"preferred_username\": \"alice\",\"email\": \"alice@example.com\"}" }
    post(path, payload)
  end

  def set_oidc_variables
    path = "cucumber:variable:conjur/authn-oidc/keycloak"
    Secret.create resource_id: "#{path}/client-id", value: oidc_client_id
    Secret.create resource_id: "#{path}/client-secret", value: oidc_client_secret
    Secret.create resource_id: "#{path}/provider-uri", value: oidc_provider_uri
  end

  def oidc_authorization_code
    path_script = "/authn-oidc/phantomjs/scripts/fetchAuthCode"
    authorization_code_file = "cat /authn-oidc/phantomjs/scripts/authorization_code"

    system("sh #{path_script}")
    @oidc_auth_code = `#{authorization_code_file}`
  end

  private

  def oidc_client_id
    @oidc_client_id ||= validated_env_var('CLIENT_ID')
  end

  def oidc_client_secret
    @oidc_client_secret ||= validated_env_var('CLIENT_SECRET')
  end

  def oidc_provider_uri
    @oidc_provider_uri ||= validated_env_var('PROVIDER_URI')
  end

  def oidc_redirect_uri
    @oidc_redirect_uri ||= validated_env_var('REDIRECT_URI')
  end

  def oidc_auth_code
    raise 'Authorization code is not initialized' if @oidc_auth_code.blank?
    @oidc_auth_code
  end

end

World(AuthnOidcHelper)