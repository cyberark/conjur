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
  authenticate_id_token_with_oidc(service_id: AuthnOidcHelper::SERVICE_ID, account: AuthnOidcHelper::ACCOUNT)
end

When(/^I authenticate via OIDC with id token and account "([^"]*)"$/) do |account|
  authenticate_id_token_with_oidc(service_id: AuthnOidcHelper::SERVICE_ID, account: account)
end

When(/^I authenticate via OIDC with no id token$/) do
  authenticate_id_token_with_oidc(service_id: AuthnOidcHelper::SERVICE_ID, account: AuthnOidcHelper::ACCOUNT, id_token: nil)
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(service_id: AuthnOidcHelper::SERVICE_ID, account: AuthnOidcHelper::ACCOUNT, id_token: "")
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
