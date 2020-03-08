Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{oidc_provider_internal_uri}/token"
  payload = { grant_type: 'password', username: username, password: password, scope: oidc_scope }
  options = { user: oidc_client_id, password: oidc_client_secret }
  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/^I successfully set OIDC variables$/) do
  set_provider_uri_variable
  set_id_token_user_property_variable
end

Given(/^I successfully set provider-uri variable$/) do
  set_provider_uri_variable
end

Given(/^I successfully set provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  set_provider_uri_variable(provider_uri)
end

Given(/^I successfully set id-token-user-property variable$/) do
  set_id_token_user_property_variable
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber')
end

When(/^I authenticate via OIDC with id token and account "([^"]*)"$/) do |account|
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: account)
end

When(/^I authenticate via OIDC with no id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: nil)
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: "")
end

When(/^I authenticate (\d+) times? in (\d+) threads? via OIDC with( invalid)? id token$/) do |num_requests, num_threads, is_invalid|
  id_token = is_invalid ? invalid_id_token : parsed_id_token

  queue = (1..num_requests.to_i).inject(Queue.new, :push)
  results = []

  all_threads = Array.new(num_threads.to_i) do
    Thread.new do
      until queue.empty?
        queue.shift
        results.push(
          Benchmark.measure do
            authenticate_id_token_with_oidc(
              service_id: 'keycloak',
              account: 'cucumber',
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

Then(/^The "([^"]*)" response time should be less than "([^"]*)" seconds$/) do |type, threshold|
  type = type.downcase.to_sym
  raise "Unexpected Type" unless %i(max avg).include?(type)
  results = @oidc_perf_results
  actual_time = type == :avg ? results.sum.fdiv(results.size) : results.max
  expect(actual_time).to be < threshold.to_f
end
