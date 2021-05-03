Then(/^(user|host) "(\S+)" has been authorized by Conjur$/) do |role_type, username|
  username = role_type == "user" ? username : "host/#{username}"
  expect(retrieved_access_token.username).to eq(username)
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(%w[user_name expiration_time id_token_encrypted], @response_body)).to be
end

Then(/it is a bad request/) do
  expect(bad_request?).to be(true), "http status is #{http_status}"
end

Then(/it is unauthorized/) do
  expect(unauthorized?).to be(true), "http status is #{http_status}"
end

Then(/it is forbidden/) do
  expect(forbidden?).to be(true), "http status is #{http_status}"
end

Then(/it is not found/) do
  expect(not_found?).to be(true), "http status is #{http_status}"
end

Then(/it is gateway timeout/) do
  expect(gateway_timeout?).to be(true), "http status is #{http_status} & rest client error is #{rest_client_error.class}"
end

Then(/it is bad gateway/) do
  expect(bad_gateway?).to be(true), "http status is #{http_status}"
end

Then(/authenticator "([^"]*)" is enabled/) do |resource_id|
  config = AuthenticatorConfig.where(resource_id: resource_id).first
  expect(config.enabled).to eq(true)
end

Then(/authenticator "([^"]*)" is disabled/) do |resource_id|
  config = AuthenticatorConfig.where(resource_id: resource_id).first
  expect(config&.enabled).to be_falsey
end

Then(/The (avg|max) authentication request responds in less than (\d+\.?(\d+)?) seconds?/) do |type, threshold|
  validate_authentication_performance(type, threshold)
end
