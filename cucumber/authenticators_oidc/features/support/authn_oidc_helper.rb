# frozen_string_literal: true

require 'securerandom'

# Utility methods for OIDC authenticator
module AuthnOidcHelper

  SERVICE_ID = 'keycloak'
  ACCOUNT = 'cucumber'

  # The OIDC authentication request should not have the host id in its URL.
  # We add this option here as users can make such a mistake and we want to verify
  # that we raise a proper error in such a case
  def authenticate_id_token_with_oidc(service_id:, account:, id_token: parsed_id_token, user_id: nil)
    path = authn_url(type: 'oidc', account: account, service_id: service_id, user_id: user_id)
    payload = {}
    unless id_token.nil?
      payload["id_token"] = id_token
    end

    post(path, payload)
  end

  def authenticate_id_token_with_oidc_in_header(service_id:, account:, id_token: parsed_id_token)
    path = authn_url(type: 'oidc', account: account, service_id: service_id)
    headers = {}
    headers["Authorization"] = "Bearer #{id_token}"
    post(path, {}, headers)
  end

  def authenticate_with_oidc_code(service_id:, account:, params: {})
    path = authn_url(type: 'oidc', account: account, service_id: service_id)
    post(path, params)
  end

  def authenticate_with_oidc_refresh_token(service_id:, account:, params: {})
    path = authn_url(type: 'oidc', account: account, service_id: service_id)
    post(path, params)
  end

  def logout_with_refresh_token(service_id:, account:, params: {})
    path = oidc_logout_url(type: 'oidc', account: account, service_id: service_id)
    puts "path: #{path}"
    puts "params: #{params}"
    post(path, params)
  end

  def oidc_logout_url(type:, account:, service_id: nil)
    path = [
      "authn-#{type}",
      service_id,
      account,
      'logout'
    ].compact.join('/')
    "#{conjur_hostname}/#{path}"
  end

  # Generic Authenticator URL builder
  def authn_url(type:, account:, service_id: nil, user_id: nil, params: {})
    path = [
      "authn-#{type}",
      service_id,
      account,
      user_id,
      'authenticate'
    ].compact.join('/')
    result = "#{conjur_hostname}/#{path}"

    unless params.empty?
      param_args = params.map{|k, v| "#{k}=#{v}"}.join('&')
      result += "?#{param_args}"
    end
    result
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

  def parse_oidc_id_token
    @oidc_id_token = (JSON.parse(@response_body))["id_token"]
  rescue => e
    raise "Failed to fetch id_token from HTTP response: #{@response_body} with Reason: #{e}"
  end

  # Verify a required set of environment variables is present.
  #
  # Note: arguments can be passed either as a string or an array of strings.
  def environment_variables_present?(*args)
    [*args].flatten.each do |variable|
      unless ENV.key?(variable) && ENV[variable].present?
        raise "Environment variable '#{variable}' must be set"
      end
    end
  end
end

World(AuthnOidcHelper)
