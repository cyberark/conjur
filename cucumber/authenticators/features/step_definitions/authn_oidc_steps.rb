Given(/^I get authorization code for username "([^"]*)" and password "([^"]*)"$/) do |username, password|
  oidc_authorization_code(username: username, password: password)
end

Given(/I fetch an ID Token/) do
  fetch_oidc_id_token
end

Given(/^I successfully set OIDC variables$/) do
  set_oidc_variables
end

Given(/^I successfully set provider-uri variable$/) do
  set_provider_uri_variable
end

Given(/^I successfully set id-token-user-property variable$/) do
  set_id_token_user_property_variable
end

When(/^I successfully login via OIDC$/) do
  login_with_oidc(service_id: 'keycloak', account: 'cucumber')
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

When(/^I authenticate "([^"]*)" times in "([^"]*)" threads via OIDC with id token$/) do |num_requests, num_threads|
  measure_oidc_performance(num_requests: num_requests.to_i, num_threads: num_threads.to_i, service_id: 'keycloak', account: 'cucumber')
end

Then(/^The "([^"]*)" response time should be less than "([^"]*)" seconds$/) do |type, threshold|
  ensure_performance_result(type, threshold.to_f)
end
