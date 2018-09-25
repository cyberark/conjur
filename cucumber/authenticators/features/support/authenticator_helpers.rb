# frozen_string_literal: true

# Utility methods for authenticators
#
module AuthenticatorHelpers

  # Mostly to document the mutable variables that are in play.
  # To at least mitigate the poor design encouraged by the way cucumber
  # shares state
  #
  attr_reader :response_body, :http_status, :rest_client_error, :ldap_auth_key

  def login_with_ldap(service_id:, account:, username:, password:)
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/login"
    get(path, user: username, password: password)
    @ldap_auth_key=response_body
  end

  def authenticate_with_ldap(service_id:, account:, username:, api_key:)
    # TODO fix this the right way
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/#{username}/authenticate"
    post(path, api_key)
  end

  def authenticate_with_oidc(service_id:, account:)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"
    payload = { code: oidc_auth_code, redirect_uri: oidc_redirect_uri }
    post(path, payload)
  end

  def token_for(username, token_string)
    return nil unless http_status == 200
    ConjurToken.new(token_string).username == username
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
    raise 'Environment variable [CLIENT_ID] is not defined' if ENV['CLIENT_ID'].blank?
    @oidc_client_id ||= ENV['CLIENT_ID']
  end

  def oidc_client_secret
    raise 'Environment variable [CLIENT_SECRET] is not defined' if ENV['CLIENT_SECRET'].blank?
    @oidc_client_secret ||= ENV['CLIENT_SECRET']
  end

  def oidc_provider_uri
    raise 'Environment variable [PROVIDER_URI] is not defined' if ENV['PROVIDER_URI'].blank?
    @oidc_provider_uri ||= ENV['PROVIDER_URI']
  end

  def oidc_redirect_uri
    raise 'Environment variable [REDIRECT_URI] is not defined' if ENV['REDIRECT_URI'].blank?
    @oidc_redirect_uri ||= ENV['REDIRECT_URI']
  end

  def oidc_auth_code
    raise 'Authorization code is not initialized' if @oidc_auth_code.blank?
    @oidc_auth_code
  end


  def set_oidc_variables
    path = "cucumber:variable:conjur/authn-oidc/keycloak"
    Secret.create resource_id: "#{path}/client-id" , value: oidc_client_id
    Secret.create resource_id: "#{path}/client-secret" , value: oidc_client_secret
    Secret.create resource_id: "#{path}/provider-uri" , value: oidc_provider_uri
  end

  def get_oidc_authorization_code
    path_script = "/authn-oidc/phantomjs/scripts/fetchAuthCode"
    authorization_code_file = "cat /authn-oidc/phantomjs/scripts/authorization_code"

    system("sh #{path_script}")
    @oidc_auth_code = %x( #{authorization_code_file} )
  end

end

World(AuthenticatorHelpers)
