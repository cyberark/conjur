Then(/^user "(\S+)" is authorized$/) do |username|
  expect(retrieved_access_token.username).to eq(username)
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(["user_name","expiration_time","id_token_encrypted"], @response_body)).to be
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

Then(/it is gateway timeout/) do
  expect(gateway_timeout?).to be(true), "http status is #{http_status} & rest client error is #{rest_client_error.class}"
end

Then(/it is bad gateway/) do
  expect(bad_gateway?).to be(true), "http status is #{http_status}"
end
