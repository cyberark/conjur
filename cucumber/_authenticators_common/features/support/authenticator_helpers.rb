# frozen_string_literal: true

# Utility methods for authenticators
#
module AuthenticatorHelpers

  MissingEnvVariable = ::Util::ErrorClass.new(
    'Environment variable [{0}] is not defined'
  )

  def validated_env_var(var)
    env_var_value = ENV[var]
    raise MissingEnvVariable, var if env_var_value.blank?

    env_var_value
  end

  # Mostly to document the mutable variables that are in play.
  # To at least mitigate the poor design encouraged by the way cucumber
  # shares state
  #
  attr_reader :response_body, :http_status, :rest_client_error, :ldap_auth_key

  def save_variable_value(account, variable_name, value)
    resource_id = [account, "variable", variable_name].join(":")
    conjur_api.resource(resource_id).add_value(value)
  end

  def retrieved_access_token
    expect(http_status).to eq(200), "Couldn't retrieve access token due to error #{rest_client_error.inspect}"
    ConjurToken.new(response_body)
  end

  def token_for_keys(keys, token_string)
    return nil unless http_status == 200

    token = JSON.parse(token_string)
    keys.all? { |k| token.key?(k) }
  rescue
    nil
  end

  def bad_request?
    http_status == 400
  end

  def unauthorized?
    http_status == 401
  end

  def forbidden?
    http_status == 403
  end

  def not_found?
    http_status == 404
  end

  def bad_gateway?
    http_status == 502
  end

  def gateway_timeout?
    # In case the client gets timeout, before the server gets timeout against the 3rd party
    http_status == 504 || client_timeout?
  end

  def load_root_policy(policy)
    conjur_api.load_policy('root', policy, method: Conjur::API::POLICY_METHOD_PUT)
  end

  def get(path, options = {})
    options = options.merge(
      method: :get,
      url: path
    )
    result             = RestClient::Request.execute(options)
    @response_body     = result.body
    @http_status       = result.code
  rescue RestClient::Exception => e
    @rest_client_error = e
    @http_status       = e.http_code
    @response_body     = e.response
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

  def execute(method, path, payload = {}, options = {})
    result             = RestClient::Request.execute(method: method, url: path, payload: payload, **options)
    @response_body     = result.body
    @http_status       = result.code
  rescue RestClient::Exception => e
    @rest_client_error = e
    @http_status       = e.http_code
    @response_body     = e.response
  end

  def conjur_hostname
    ENV.fetch('CONJUR_APPLIANCE_URL', 'http://conjur')
  end

  private

  def admin_password
    'SEcret12!!!!'
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
      full_username(username)
    ).rotate_api_key
    Conjur::API.new_from_key(username, api_key)
  end

  def full_username(username, account: Conjur.configuration.account)
    "#{account}:user:#{username}"
  end

  def client_timeout?
    rest_client_error.instance_of?(RestClient::Exceptions::ReadTimeout)
  end

  def authenticate_with_performance(num_requests, num_threads, authentication_func:, authentication_func_params:)
    queue   = (1..num_requests.to_i).inject(Queue.new, :push)
    results = []

    all_threads = Array.new(num_threads.to_i) do
      Thread.new do
        until queue.empty?
          queue.shift
          results.push(
            Benchmark.measure do
              method(authentication_func).call(**authentication_func_params)
            end
          )
        end
      end
    end

    all_threads.each(&:join)
    @authentication_perf_results = results.map(&:real)
  end

  def validate_authentication_performance(type, threshold)
    type        = type.downcase.to_sym
    results     = @authentication_perf_results
    actual_time = type == :avg ? results.sum.fdiv(results.size) : results.max
    expect(actual_time).to be < threshold.to_f
  end
end

World(AuthenticatorHelpers)
