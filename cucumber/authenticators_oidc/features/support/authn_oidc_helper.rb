# frozen_string_literal: true
require 'securerandom'

# Utility methods for OIDC authenticator
module AuthnOidcHelper

  V2_SERVICE_ID = 'keycloak2'
  SERVICE_ID = 'keycloak'
  ACCOUNT = 'cucumber'

  # The OIDC authentication request should not have the host id in its URL.
  # We add this option here as users can make such a mistake and we want to verify
  # that we raise a proper error in such a case
  def authenticate_id_token_with_oidc(service_id:, account:, id_token: parsed_id_token, user_id: "")
    service_id_part = service_id ? "/#{service_id}" : ""
    user_id_part = "/#{user_id}" unless user_id.nil? || user_id.empty?
    path = "#{conjur_hostname}/authn-oidc#{service_id_part}/#{account}#{user_id_part}/authenticate"

    payload = {}
    unless id_token.nil?
      payload["id_token"] = id_token
    end

    post(path, payload)
  end

  def authenticate_code_with_oidc(service_id:, account:, code: url_oidc_code, state: url_oidc_state)
    path = "#{create_auth_url(service_id: service_id, account: account, user_id: nil)}"
    get(url_with_params(path: path,code: code, state: state ))
  end

  def create_auth_url(service_id:, account:, user_id:)
    service_id_part = service_id ? "/#{service_id}" : ""
    user_id_part = "/#{user_id}" unless user_id.nil? || user_id.empty?
    "#{conjur_hostname}/authn-oidc#{service_id_part}/#{account}#{user_id_part}/authenticate"
  end

  def url_with_params(path:, code: nil, state: nil)
    return path unless code || state

    "#{path}?code=#{code}&state=#{state}"
  end

  def create_oidc_secret(variable_name, value, service_id_suffix = "keycloak")
    path = "cucumber:variable:conjur/authn-oidc/#{service_id_suffix}".chomp("/")
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

  def parsed_id_token
    @oidc_id_token.to_s
  end

  def oidc_code(oidc_code:)
    @oidc_code = oidc_code
  end

  def invalid_id_token
    "invalididtoken"
  end

  private

  def oidc_client_id
    @oidc_client_id ||= validated_env_var('KEYCLOAK_CLIENT_ID')
  end

  def oidc_client_secret
    @oidc_client_secret ||= validated_env_var('KEYCLOAK_CLIENT_SECRET')
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

  def oidc_scope
    @oidc_scope ||= validated_env_var('KEYCLOAK_SCOPE')
  end

  def oidc_required_request_parameters
    @oidc_required_request_parameters ||= 'code state'
  end

  def parse_oidc_id_token
    @oidc_id_token = (JSON.parse(@response_body))["id_token"]
  rescue => e
    raise "Failed to fetch id_token from HTTP response: #{@response_body} with Reason: #{e}"
  end

  def oidc_response_type
    @oidc_response_type ||= 'code'
  end

  def oidc_claim_mapping
    @oidc_claim_mapping ||= 'preferred_username'
  end

  def oidc_state
    @oidc_state ||= SecureRandom.uuid
  end

  def oidc_nonce
    @oidc_nonce ||= SecureRandom.uuid
  end

  def oidc_redirect_uri
    @oidc_redirect_uri ||= 'http://conjur:3000/authn-oidc/keycloak2/cucumber/authenticate'
  end

  def parse_oidc_code(url)
    params = CGI::parse(URI(url).query)
    @url_oidc_code = params["code"][0] if params.has_key?("code")
    @url_oidc_state = params["state"][0] if params.has_key?("state")
  end

  def url_oidc_code
    @url_oidc_code
  end

  def url_oidc_code
    @url_oidc_code
  end

  def url_oidc_state
    @url_oidc_state
  end
end

World(AuthnOidcHelper)
