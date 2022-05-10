Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{oidc_provider_internal_uri}/token"
  payload = { grant_type: 'password', username: username, password: password, scope: oidc_scope }
  options = { user: oidc_client_id, password: oidc_client_secret }
  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/I fetch a code for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  Rails.application.config.conjur_config.authenticators = ['authn-oidc/keycloak2']
  authentication_handler = Authentication::Handler::OidcAuthenticationHandler.new
  uri = URI(authentication_handler.get_login_url(
    service_id: AuthnOidcHelper::V2_SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  ))

  res = Net::HTTP.get_response(uri)
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
  create_oidc_secret("scope", oidc_scope, "/keycloak2")
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
