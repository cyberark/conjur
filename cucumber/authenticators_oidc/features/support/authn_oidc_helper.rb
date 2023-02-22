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

  def authenticate_id_token_with_oidc_in_header(service_id:, account:, id_token: parsed_id_token)
    service_id_part = service_id ? "/#{service_id}" : ""
    path = "#{conjur_hostname}/authn-oidc#{service_id_part}/#{account}/authenticate"
    headers = {}
    headers["Authorization"] = "Bearer #{id_token}"
    post(path, {}, headers)
  end

  def authenticate_code_with_oidc(service_id:, account:, code:, nonce:, code_verifier:)
    path = create_auth_url(service_id: service_id, account: account, user_id: nil).to_s
    get(url_with_params(path: path, code: code, nonce: nonce, code_verifier: code_verifier))
  end

  def create_auth_url(service_id:, account:, user_id:)
    service_id_part = service_id ? "/#{service_id}" : ""
    user_id_part = "/#{user_id}" unless user_id.nil? || user_id.empty?
    "#{conjur_hostname}/authn-oidc#{service_id_part}/#{account}#{user_id_part}/authenticate"
  end

  def url_with_params(path:, **kargs)
    return path unless kargs

    "#{path}?#{URI.encode_www_form(kargs)}"
  end

  def create_oidc_secret(variable_name, value, service_id_suffix = "keycloak")
    path = "cucumber:variable:conjur/authn-oidc/#{service_id_suffix}".chomp("/")
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

  def parsed_id_token
    @oidc_id_token.to_s
  end

  def invalid_id_token
    "invalididtoken"
  end

  private

  def parse_oidc_id_token
    @oidc_id_token = (JSON.parse(@response_body))["id_token"]
  rescue => e
    raise "Failed to fetch id_token from HTTP response: #{@response_body} with Reason: #{e}"
  end

  def parse_oidc_code(url)
    params = CGI::parse(URI(url).query)
    {}.tap do |response|
      response[:code] = params["code"][0] if params.key?("code")
      response[:state] =  params["state"][0] if params.key?("state")
    end
  end
end

World(AuthnOidcHelper)
