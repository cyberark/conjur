Given(/I get authorization code/) do
  get_oidc_authorization_code
end

Given(/I successfully set OIDC variables/) do
  set_oidc_variables
end

When(/I successfully authenticate via OIDC/) do
  authenticate_with_oidc(service_id: 'keycloak', account: 'cucumber')
end
