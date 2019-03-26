Given(/^I get authorization code for username "([^"]*)" and password "([^"]*)"$/) do |username, password|
  oidc_authorization_code(username: username, password: password)
end

Given(/I fetch an ID Token/) do
  fetch_oidc_id_token
end

Given(/^I successfully set OIDC variables$/) do
  set_oidc_variables
end

When(/^I successfully login via OIDC$/) do
  login_with_oidc(service_id: 'keycloak', account: 'cucumber')
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber')
end

When(/^I authenticate via OIDC with no id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: nil)
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: "")
end
