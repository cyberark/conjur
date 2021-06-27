Given(/I initialize JWKS endpoint with file "([^"]*)"/) do |filename|
  init_jwks_file(filename)
end

Given(/I issue a JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue unknown kid JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token_unkown_kid(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue another key JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token_not_memoized_key(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue a JWT token without exp:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(
    JSON.parse(token_body_string)
  )
end

Given(/I issue empty JWT token/) do
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(JSON.parse("{}"))
end
