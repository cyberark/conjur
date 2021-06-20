Given(/I successfully set authn-jwt jwks-uri variable with value of "([^"]*)" endpoint/) do |filename|
  create_jwt_secret("jwks-uri", "#{JwtJwksHelper::JWKS_BASE_URI}/#{filename}")
end

Given(/I successfully set authn-jwt "([^"]*)" variable to value "([^"]*)"/) do |variable, value|
  create_jwt_secret(variable, value)
end

When(/I authenticate via authn-jwt with the JWT token/) do
  authenticate_jwt_token(jwt_token)
end

When(/I authenticate via authn-jwt with ([^"]*) service ID/) do |service_id|
  authenticate_jwt_token(jwt_token, service_id)
end

When(/I authenticate via authn-jwt with ([^"]*) account in url/) do |account|
  authenticate_jwt_with_url_identity(jwt_token, account)
end
