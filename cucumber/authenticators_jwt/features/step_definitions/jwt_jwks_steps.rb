Given(/I initialize JWKs endpoint with file "([^"]*)"/) do |filename|
  init_jwks_file(filename)
end

Given(/I issue a JWT token using key "([^"]*)":/) do |key_name, token_body_string|
  # token body has to be an object (not a string) for correct token creation
  issue_jwt_token(
    token_body_with_valid_expiration(
      JSON.parse(token_body_string)
    ),
    key_name
  )
end
