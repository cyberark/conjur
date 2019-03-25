# frozen_string_literal: true
#
# Utility methods for OIDC authenticator
#
module AuthnOidcHelper
  include AuthenticatorHelpers

  # relevant for original oidc flow
  # def login_with_oidc(service_id:, account:)
  #   path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/login"
  #   payload = { code: oidc_auth_code, redirect_uri: oidc_redirect_uri }
  #   post(path, payload)
  #   @login_oidc_conjur_token = @response_body
  # end

  # # relevant for oidc flow for Conjur oidc token retrieved in oidc login flow
  # def authenticate_conjur_oidc_token_with_oidc(service_id:, account:)
  #   path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"
  #   # TODO: Since the input going to change to a base64 signed token, i didnt invest time to extract the real values
  #   payload = { id_token_encrypted: "login_oidc_conjur_token", user_name: "alice", expiration_time: "1231" }
  #   post(path, payload)
  # end

  def authenticate_id_token_with_oidc(service_id:, account:)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"
    payload = { id_token: @oidc_id_token.to_s }
    post(path, payload)
  end

  def oidc_authorization_code(username:, password:)
    path_script = "/authn-oidc/phantomjs/scripts/fetchAuthCode"
    params = "#{username} #{password}"
    system("#{path_script} #{params}")

    @oidc_auth_code = `#{"cat /authn-oidc/phantomjs/scripts/authorization_code"}`
  end

  def fetch_oidc_id_token
    path = "#{oidc_provider_internal_uri}/token"
    payload = { grant_type: 'authorization_code', redirect_uri: oidc_redirect_uri, code: oidc_auth_code }
    options = { user: oidc_client_id, password: oidc_client_secret }
    execute(:post, path, payload, options)
    parse_oidc_id_token
  end

  def set_oidc_variables
    path = "cucumber:variable:conjur/authn-oidc/keycloak"
    Secret.create(resource_id: "#{path}/provider-uri", value: oidc_provider_uri)
    Secret.create(resource_id: "#{path}/id-token-user-property", value: oidc_id_token_user_property)
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

  def oidc_provider_internal_uri
    @oidc_provider_internal_uri ||= validated_env_var('PROVIDER_INTERNAL_URI')
  end

  def oidc_id_token_user_property
    @oidc_id_token_user_property ||= validated_env_var('ID_TOKEN_USER_PROPERTY')
  end

  def oidc_redirect_uri
    @oidc_redirect_uri ||= validated_env_var('REDIRECT_URI')
  end

  def oidc_auth_code
    if @oidc_auth_code.blank?
      raise 'Authorization code is not initialized, Additional logs exists in keycloak_login.[date].log file'
    end
    @oidc_auth_code
  end

  def parse_oidc_id_token
    @oidc_id_token = (JSON.parse @response_body)["id_token"]
  rescue Exception => err
    raise "Failed to fetch id_token from HTTP response: #{@response_body} with Reason: #{err}"
  end
end

World(AuthnOidcHelper)
