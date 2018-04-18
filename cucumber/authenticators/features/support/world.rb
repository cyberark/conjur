module AuthenticatorWorld

  # mostly to document the mutable variables that are in play
  attr_reader :response_body, :http_status, :rest_client_error 

  class ConjurToken
    def initialize(raw_token)
      @token = JSON.parse(raw_token)
    end

    def username
      payload['sub']
    end

    private

    def payload
      @payload ||= JSON.parse(Base64.decode64(@token['payload']))
    end
  end

  def authenticate_with_ldap(service_id:, account:, username:, password:)
    # TODO fix this the right way
    path = "http://localhost:3000/authn-ldap/#{service_id}/#{account}/#{username}/authenticate"
    post(path, password)
  end

  def valid_token_for?(username, token_string)
    return false unless http_status == 200
    ConjurToken.new(token_string).username == username
  rescue
    false
  end

  def post(path, payload, options = {})
    result             = RestClient.post(path, payload, options)
    @response_body     = result.body
    @http_status       = result.code
  rescue RestClient::Exception => e
    @rest_client_error = e
    @http_status       = e.http_code
    @response_body     = e.response
  end

  def load_root_policy(policy)
    conjur_api.load_policy('root', policy,
                           method: Conjur::API::POLICY_METHOD_PUT)
  end

  private

  def admin_password
    ENV['CONJUR_AUTHN_PASSWORD'] || 'admin'
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

end

World(AuthenticatorWorld)
