Given(/I successfully set authn-jwt jwks-uri variable with value of "([^"]*)" endpoint/) do |filename|
  create_jwt_secret(variable_name: "jwks-uri", value: "#{JwtJwksHelper::JWKS_BASE_URI}/#{filename}")
end

Given(/I successfully set authn-jwt jwks-uri variable with value of "([^"]*)" in service "([^"]*)"/) do |filename, service_id|
  create_jwt_secret(variable_name: "jwks-uri", value: "#{JwtJwksHelper::JWKS_BASE_URI}/#{filename}", service_id: service_id)
end

Given(/I successfully set authn-jwt "([^"]*)" variable to value "([^"]*)"/) do |variable, value|
  create_jwt_secret(variable_name: variable, value: value)
end

Given(/I successfully set authn-jwt "([^"]*)" variable value to "([^"]*)" in service "([^"]*)"/) do |variable, value, service_id|
  create_jwt_secret(variable_name: variable, value: value, service_id: service_id)
end

Given(/I successfully set authn-jwt "([^"]*)" variable with OIDC value from env var "([^"]*)"/) do |variable, env_var|
  create_jwt_secret_with_oidc_as_provider_uri(variable_name: variable, value: validated_env_var(env_var))
end

Given(/I successfully set authn-jwt "([^"]*)" variable in keycloack service to "([^"]*)"/) do |variable, value|
  create_jwt_secret_with_oidc_as_provider_uri(variable_name: variable, value: value)
end

Given(/I successfully set authn-jwt public-keys variable with value from "([^"]*)" endpoint/) do |filename|
  get("#{JwtJwksHelper::JWKS_BASE_URI}/#{filename}")
  create_public_keys_from_response_body
end

Given(/^I successfully set authn-jwt public-keys variable to value from remote JWKS endpoint "([^"]*)" and alg "([^"]*)"$/) do |file_name, alg|
  init_jwks_remote_file(file_name, alg)
  create_public_keys_from_response_body
end

When(/I authenticate via authn-jwt using given ([^"]*) service ID and without account in url/) do |service_id|
  authenticate_jwt_token(jwt_token, service_id)
end

When(/I authenticate via authn-jwt with the JWT token/) do
  authenticate_jwt_token(jwt_token)
end

When(/I authenticate via authn-jwt with ([^"]*) service ID/) do |service_id|
  authenticate_jwt_token(jwt_token, service_id)
end

When(/I authenticate via authn-jwt using given ([^"]*) service ID and with ([^"]*) account in url/) do |service_id, account|
  authenticate_jwt_with_url_identity(jwt_token, account, service_id)
end

When(/I authenticate via authn-jwt without service id but with ([^"]*) account in url/) do |account|
  authenticate_jwt_token(jwt_token, account)
end

When(/I authenticate via authn-jwt with ([^"]*) account in url/) do |account|
  authenticate_jwt_with_url_identity(jwt_token, account)
end

When(/I authenticate via authn-jwt with the ID token/) do
  authenticate_jwt_with_oidc_as_provider_uri
end

When (/I authenticate with string that is not token ([^"]*)/) do |text|
  authenticate_jwt_token(text)
end
