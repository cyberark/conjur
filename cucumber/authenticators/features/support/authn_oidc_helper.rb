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

  def authenticate_id_token_with_oidc(service_id:, account:, id_token: @oidc_id_token.to_s)
    path = "#{conjur_hostname}/authn-oidc/#{service_id}/#{account}/authenticate"

    payload = {}
    unless id_token.nil?
      payload["id_token"] = id_token
    end

    post(path, payload)
  end

  def oidc_authorization_code(username:, password:)
    path_script = "/authn-oidc/phantomjs/scripts/fetchAuthCode"
    params = "#{username} #{password}"
    system("#{path_script} #{params}")

    @oidc_auth_code = `#{"cat /authn-oidc/phantomjs/scripts/authorization_code"}`
    expect(@oidc_auth_code).not_to be_empty, "couldn't fetch authorization code"
  end

  def fetch_oidc_id_token
    path = "#{oidc_provider_internal_uri}/token"
    payload = { grant_type: 'authorization_code', redirect_uri: oidc_redirect_uri, code: oidc_auth_code }
    options = { user: oidc_client_id, password: oidc_client_secret }
    execute(:post, path, payload, options)
    parse_oidc_id_token
  end

  def set_oidc_variables
    set_provider_uri_variable
    set_id_token_user_property_variable
  end

  def set_provider_uri_variable(value = oidc_provider_uri)
    set_oidc_variable("provider-uri", value)
  end

  def set_id_token_user_property_variable
    set_oidc_variable("id-token-user-property", oidc_id_token_user_property)
  end

  def set_oidc_variable(variable_name, value)
    path = "cucumber:variable:conjur/authn-oidc/keycloak"
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

  def measure_oidc_performance(num_requests:, num_threads:, service_id:, account:, id_token: @oidc_id_token.to_s)
    queue = (1..num_requests).inject(Queue.new, :push)
    results = []

    all_threads = Array.new(num_threads) do
      Thread.new do
        until queue.empty? do
          queue.shift
          results.push(
              Benchmark.measure do
                authenticate_id_token_with_oidc(
                    service_id: service_id,
                    account: account,
                    id_token: id_token
                )
              end
          )
        end
      end
    end

    all_threads.each(&:join)
    @oidc_perf_results = results.map(&:real)
  end

  def ensure_performance_result(type_str, threshold)
    type = type_str.downcase.to_sym
    raise "Unexpected Type" unless [:max, :avg].include?(type)
    results = @oidc_perf_results
    actual_time = (type == :avg) ? results.sum.fdiv(results.size) : results.max
    expect(actual_time).to be < threshold
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
