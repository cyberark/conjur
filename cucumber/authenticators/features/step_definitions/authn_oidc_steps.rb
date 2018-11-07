Given(/I get authorization code/) do
  oidc_authorization_code
end

Given(/I successfully set OIDC variables/) do
  set_oidc_variables
end

When(/I successfully login via OIDC/) do
  login_with_oidc(service_id: 'keycloak', account: 'cucumber')
end

When(/I successfully authenticate via OIDC/) do
  authenticate_with_oidc(service_id: 'keycloak', account: 'cucumber')
end
