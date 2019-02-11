# frozen_string_literal: true

require 'util/error_class'

# Utility methods for authenticators
#
module AuthenticatorHelpers

  MissingEnvVarirable = ::Util::ErrorClass.new(
    'Environment variable [{0}] is not defined'
  )

  def validated_env_var(var)
    raise MissingEnvVarirable, var if ENV[var].blank?
    ENV[var]
  end

  # Mostly to document the mutable variables that are in play.
  # To at least mitigate the poor design encouraged by the way cucumber
  # shares state
  #
  attr_reader :response_body, :http_status, :rest_client_error, :ldap_auth_key

  def login_with_ldap(service_id:, account:, username:, password:)
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/login"
    get(path, user: username, password: password)
    @ldap_auth_key = response_body
  end

  def authenticate_with_ldap(service_id:, account:, username:, api_key:)
    # TODO fix this the right way
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/#{username}/authenticate"
    post(path, api_key)
  end

  def save_variable_value(account, variable_name, value)
    resource_id = [account, "variable", variable_name].join(":")
    conjur_api.resource(resource_id).add_value(value)
  end

  def ldap_ca_certificate_value
    @ldap_ca_certificate_value ||= File.read('/ldap-certs/root.cert.pem')
  end

  def login_with_oidc(service_id:, account:)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/login"
    payload = { code: oidc_auth_code, redirect_uri: oidc_redirect_uri }
    post(path, payload)
    @login_oidc_conjur_token = @response_body
  end

  def authenticate_with_oidc(service_id:, account:)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"
    # TODO: Since the input going to change to a base64 signed token, i didnt invest time to extract the real values
    payload = { id_token_encrypted: "login_oidc_conjur_token", user_name: "alice", expiration_time: "1231" }
    post(path, payload)
  end

  def token_for(username, token_string)
    return nil unless http_status == 200
    ConjurToken.new(token_string).username == username
  rescue
    nil
  end

  def token_for_keys(keys, token_string)
    return nil unless http_status == 200
    token = JSON.parse(token_string)
    keys.all? { |k| token.key? k }
  rescue
    nil
  end

  def unauthorized?
    http_status == 401
  end

  def forbidden?
    http_status == 403
  end

  def load_root_policy(policy)
    conjur_api.load_policy('root', policy,
                           method: Conjur::API::POLICY_METHOD_PUT)
  end

  private

  def get(path, options = {})
    options = options.merge(
      method: :get,
      url: path
    )
    result             = RestClient::Request.execute(options)
    @response_body     = result.body
    @http_status       = result.code
  rescue RestClient::Exception => err
    @rest_client_error = err
    @http_status       = err.http_code
    @response_body     = err.response
  end

  def post(path, payload, options = {})
    result             = RestClient.post(path, payload, options)
    @response_body     = result.body
    @http_status       = result.code

  rescue RestClient::Exception => err
    @rest_client_error = err
    @http_status       = err.http_code
    @response_body     = err.response
  end

  def conjur_hostname
    ENV.fetch('CONJUR_APPLIANCE_URL', 'http://conjur')
  end

  def admin_password
    ENV['CONJUR_AUTHN_API_KEY'] || 'admin'
  end

  def admin_api_key
    @admin_api_key ||= Conjur::API.login('admin', admin_password)
  end

  def conjur_api
    @conjur_api ||= api_for('admin', admin_api_key)
  end

  def api_for(username, api_key = nil)
    api_key = admin_api_key if username == 'admin'
    api_key ||= Conjur::API.new_from_key('admin', admin_api_key).role(
                  full_username(username)).rotate_api_key
    Conjur::API.new_from_key(username, api_key)
  end

  def full_username(username, account: Conjur.configuration.account)
    "#{account}:user:#{username}"
  end

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

end

World(AuthenticatorHelpers)
