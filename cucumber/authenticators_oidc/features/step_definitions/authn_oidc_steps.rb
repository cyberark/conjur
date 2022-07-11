Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{oidc_provider_internal_uri}/token"
  payload = { grant_type: 'password', username: username, password: password, scope: oidc_scope }
  options = { user: oidc_client_id, password: oidc_client_secret }
  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/I fetch a code for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  Rails.application.config.conjur_config.authenticators = ['authn-oidc/keycloak2']

  @client = Client.for('user', 'admin')
  providers = @client.fetch_authenticators
  url = providers.body.map { |x| x["redirect_uri"] }

  res = Net::HTTP.get_response(URI(url[0]))
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
  request.set_form_data({'username' => username, 'password' => password})

  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location'])
  end
end

Given(/^I fetch a code from okta for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  uri = URI("https://#{URI(okta_provider_uri).host}/api/v1/authn")
  body = JSON.generate({ username: username, password: password })

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request['Accept'] = 'application/json'
  request['Content-Type'] = 'application/json'
  request.body = body

  response = http.request(request)
  session_token = JSON.parse(response.body)["sessionToken"]

  oidc_parameters = {
    client_id: okta_client_id,
    redirect_uri: okta_redirect_uri,
    response_type: oidc_response_type,
    scope: okta_scope,
    state: oidc_state,
    nonce: oidc_nonce,
    sessionToken: session_token
  }

  query_string = ""
  oidc_parameters.each {|key, value| query_string += "#{key}=#{value}&"}
  uri = URI("#{okta_provider_uri}/v1/authorize?#{query_string}")
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location'])
  end
end

Given(/^I successfully set OIDC variables$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
end

Given(/^I successfully set OIDC V2 variables$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri, "/keycloak2")
  create_oidc_secret("response-type", oidc_response_type, "/keycloak2")
  create_oidc_secret("client-id", oidc_client_id, "/keycloak2")
  create_oidc_secret("client-secret", oidc_client_secret, "/keycloak2")
  create_oidc_secret("claim-mapping", oidc_claim_mapping, "/keycloak2")
  create_oidc_secret("state", oidc_state, "/keycloak2")
  create_oidc_secret("nonce", oidc_nonce, "/keycloak2")
  create_oidc_secret("redirect-uri", oidc_redirect_uri, "/keycloak2")
  create_oidc_secret("provider_scope", oidc_scope, "/keycloak2")
end

Given(/^I successfully set Okta OIDC V2 variables$/) do
  create_oidc_secret("provider-uri", okta_provider_uri, "/okta-2")
  create_oidc_secret("client-id", okta_client_id, "/okta-2")
  create_oidc_secret("client-secret", okta_client_secret, "/okta-2")
  create_oidc_secret("claim-mapping", oidc_claim_mapping, "/okta-2")
  create_oidc_secret("state", oidc_state, "/okta-2")
  create_oidc_secret("nonce", oidc_nonce, "/okta-2")
  create_oidc_secret("redirect-uri", okta_redirect_uri, "/okta-2")
end

Given(/^I successfully set OIDC variables without a service-id$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri, "")
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property, "")
end

Given(/^I successfully set provider-uri variable$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
end

Given(/^I successfully set provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  create_oidc_secret("provider-uri", provider_uri)
end

Given(/^I successfully set id-token-user-property variable$/) do
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
end

When(/^I authenticate via OIDC V2 with code$/) do
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with code$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
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

When(/^I authenticate via OIDC V2 with code and service-id "([^"]*)"$/) do |service_id|
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

When(/^I authenticate via OIDC V2 with code "([^"]*)"$/) do |code|
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    code: code,
  )
end

When(/^I authenticate via OIDC V2 with state "([^"]*)"$/) do |state|
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    state: state,
  )
end

When(/^I authenticate via OIDC V2 with no code in the request$/) do
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    code: nil,
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
