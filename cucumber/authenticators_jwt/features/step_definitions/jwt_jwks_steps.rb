Given(/I initialize JWKS endpoint with file "([^"]*)"/) do |filename|
  init_jwks_file(filename)
end

Given(/I initialize JWKS endpoint "([^"]*)" with the same kid as "([^"]*)"/) do |second_file_name, first_file_name|
  init_second_jwks_file_with_same_kid(first_file_name, second_file_name)
end

Given(/I initialize ECDSA JWKS endpoint with file "([^"]*)" with key type "([^"]*)"/) do |filename, key_type|
  init_ecdsa_jwks_file(filename, key_type)
end

Given(/I initialize HMAC JWKS endpoint with file "([^"]*)"/) do |filename|
  init_hmac_jwks_file(filename)
end

Given(/I issue a JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue an ECDSA JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_ecdsa_token(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue an "([^"]*)" alg header RS256 JWT token:/) do |alg_header, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_rsa_jwt_token_with_alg_header(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    alg_header
  )
end

Given(/I issue an "([^"]*)" algorithm RSA JWT token:/) do |algorithm, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    algorithm
  )
end

Given(/I issue an "([^"]*)" algorithm ECDSA JWT token:/) do |algorithm, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_ecdsa_token(
    token_body = token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    algorithm
  )
end

Given(/I issue an "([^"]*)" algorithm HMAC JWT token:/) do |algorithm, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_hmac_token(
    token_body = token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    algorithm
  )
end

Given(/I issue a JWT token signed with jku with jwks file_name "([^"]*)":/) do |file_name, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token_with_jku(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    file_name
  )
end

Given(/I issue a JWT token signed with jwk with jwks file_name "([^"]*)":/) do |file_name, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token_with_jwk(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    file_name
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

Given(/I issue HMAC JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_hmac_token_token_with_rsa_key(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    )
  )
end

Given(/I issue none alg JWT token:/) do |token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_none_alg_jwt_token(
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
