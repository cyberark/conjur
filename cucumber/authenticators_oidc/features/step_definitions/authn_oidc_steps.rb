Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{oidc_provider_internal_uri}/token"
  payload = { grant_type: 'password', username: username, password: password, scope: oidc_scope }
  options = { user: oidc_client_id, password: oidc_client_secret }
  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/I fetch a code for username "([^"]*)" and password "([^"]*)" from "([^"]*)"/) do |username, password, service_id|
  Rails.application.config.conjur_config.authenticators = ["authn-oidc/#{service_id}"]

  # Retrieve the specified authenticator provider
  provider = JSON.parse(
    Net::HTTP.get(
      URI("#{conjur_hostname}/authn-oidc/cucumber/providers")
    )
  ).first { |p| p['service_id'] == service_id }

  @scenario_context.add(:nonce, provider['nonce'])

  # The version of Keycloak we're using does not accept PKCE. We need
  # to strip code challenge and code challenge args from the redirect
  # URI
  redirect_uri = URI.parse(provider['redirect_uri'])
  params = URI.decode_www_form(redirect_uri.query).to_h
  params.delete('code_challenge')
  params.delete('code_challenge_method')
  redirect_uri.query = URI.encode_www_form(params)

  res = Net::HTTP.get_response(redirect_uri)
  raise res if res.is_a?(Net::HTTPError) || res.is_a?(Net::HTTPClientError)

  all_cookies = res.get_fields('set-cookie')
  cookies_arrays = Array.new
  all_cookies.each do |cookie|
    cookies_arrays.push(cookie.split('; ')[0])
  end

  html = Nokogiri::HTML(res.body)
  post_uri = URI(html.xpath('//form').first.attributes['action'].value)

  http = Net::HTTP.new(post_uri.host, post_uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(post_uri.request_uri)
  request['Cookie'] = cookies_arrays.join('; ')
  request.set_form_data({ 'username' => username, 'password' => password })

  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location'])
  end
end

Given(/^I load a policy with okta user:/) do |policy|
  user_policy = """
  - !user #{ENV['OKTA_USERNAME']}

  - !grant
    role: !group conjur/authn-oidc/okta-2/users
    member: !user #{ENV['OKTA_USERNAME']}"""

  load_root_policy(policy + user_policy)
end

Given(/^I retrieve OIDC configuration from the provider endpoint for "([^"]*)"/) do |service_id|
  provider = JSON.parse(
    Net::HTTP.get(
      URI("#{conjur_hostname}/authn-oidc/cucumber/providers")
    )
  ).first { |p| p['service_id'] == service_id }
  @scenario_context.add(:nonce, provider['nonce'])
  @scenario_context.add(:code_verifier, provider['code_verifier'])
  @scenario_context.add(:redirect_uri, provider['redirect_uri'])
end

Given(/^I authenticate and fetch a code from Okta/) do
  uri = URI("https://#{URI(okta_provider_uri).host}/api/v1/authn")
  body = JSON.generate({ username: ENV['OKTA_USERNAME'], password: ENV['OKTA_PASSWORD'] })

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request['Accept'] = 'application/json'
  request['Content-Type'] = 'application/json'
  request.body = body

  response = http.request(request)
  session_token = JSON.parse(response.body)["sessionToken"]

  uri = URI("#{@scenario_context.get(:redirect_uri)}&state=test-state&sessionToken=#{session_token}")
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location'])
  else
    raise "Failed to retrieve OIDC code status: #{response.code}"
  end
end

Given(/^I successfully set OIDC variables$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
end

When(/^I authenticate via OIDC V2 with code$/) do
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT
  )
end

Given(/^I successfully set Okta OIDC V2 variables$/) do
  create_oidc_secret("provider-uri", okta_provider_uri, "okta-2")
  create_oidc_secret("client-id", okta_client_id, "okta-2")
  create_oidc_secret("client-secret", okta_client_secret, "okta-2")
  create_oidc_secret("claim-mapping", oidc_claim_mapping, "okta-2")
  create_oidc_secret("state", oidc_state, "okta-2")
  create_oidc_secret("nonce", oidc_nonce, "okta-2")
  create_oidc_secret("redirect-uri", okta_redirect_uri, "okta-2")
end

Given(/^I successfully set OIDC variables without a service-id$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri, "")
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property, "")
end

Given(/^I successfully set provider-uri variable$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
end

When(/^I authenticate via OIDC V2 with code "([^"]*)"$/) do |code|
  @scenario_context.add(:code, code)
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC V2 with no code in the request$/) do
  @scenario_context.add(:code, nil)
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT
  )
end

Given(/^I successfully set provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  create_oidc_secret("provider-uri", provider_uri)
end

Given(/^I successfully set id-token-user-property variable$/) do
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with id token in header$/) do
  authenticate_id_token_with_oidc_in_header(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
end

Given(/^I successfully set OIDC V2 variables for "([^"]*)"$/) do |service_id|
  create_oidc_secret("provider-uri", oidc_provider_uri, service_id)
  create_oidc_secret("response-type", oidc_response_type, service_id)
  create_oidc_secret("client-id", oidc_client_id, service_id)
  create_oidc_secret("client-secret", oidc_client_secret, service_id)
  create_oidc_secret("claim-mapping", oidc_claim_mapping, service_id)
  create_oidc_secret("state", oidc_state, service_id)
  create_oidc_secret("nonce", oidc_nonce, service_id)
  create_oidc_secret("redirect-uri", oidc_redirect_uri, service_id)
  create_oidc_secret("provider-scope", oidc_scope, service_id)
end

Given(/^I set a custom token TTL of "([^"]*)" for "([^"]*)"$/) do |duration_iso8601, service_id|
  create_oidc_secret("token-ttl", duration_iso8601, service_id)
end

When(/^I authenticate via OIDC V2 with code and service-id "([^"]*)"$/) do |service_id|
  authenticate_code_with_oidc(
    service_id: service_id,
    account: AuthnOidcHelper::ACCOUNT
  )
end

Then(/^the okta user has been authorized by conjur/) do
  username = ENV['OKTA_USERNAME']
  expect(retrieved_access_token.username).to eq(username)
end

Then(/^user "(\S+)" has been authorized by Conjur for (\d+) (\S+)$/) do |username, duration, duration_unit|
  token = retrieved_access_token
  expect(token.username).to eq(username)

  case duration_unit
  when /hours?/
    expected_duration = duration * 3600
  when /minutes?/
    expected_duration = duration * 60
  when /seconds?/
    expected_duration = duration
  end
  expect(token.duration).to eq(expected_duration)
end

When(/^I authenticate via OIDC with id token and without a service-id$/) do
  authenticate_id_token_with_oidc(
    service_id: nil,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with id token and account "([^"]*)"$/) do |account|
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: account
  )
end

When(/^I authenticate via OIDC V2 with code and account "([^"]*)"$/) do |account|
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: account
  )
end

When(/^I authenticate via OIDC with code and service_id "([^"]*)"$/) do |service_id|
  authenticate_code_with_oidc(
    service_id: service_id,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with no id token( and user id "([^"]*)" in the request)?$/) do |user_id|
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT,
    id_token: nil,
    user_id: user_id
  )
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT,
    id_token: ""
  )
end

When(/^I authenticate (\d+) times? in (\d+) threads? via OIDC with( invalid)? id token$/) do |num_requests, num_threads, is_invalid|
  id_token = is_invalid ? invalid_id_token : parsed_id_token

  authenticate_with_performance(
    num_requests,
    num_threads,
    authentication_func: :authenticate_id_token_with_oidc,
    authentication_func_params: {
      service_id: AuthnOidcHelper::SERVICE_ID,
      account: AuthnOidcHelper::ACCOUNT,
      id_token: id_token
    }
  )
end
