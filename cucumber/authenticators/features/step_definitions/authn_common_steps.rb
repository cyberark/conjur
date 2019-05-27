Then(/^user "(\S+)" is authorized$/) do |username|
  expect(token_for(username, @response_body)).to be
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(["user_name","expiration_time","id_token_encrypted"], @response_body)).to be
end

Then(/it is a bad request/) do
  expect(bad_request?).to be true
end

Then(/it is unauthorized/) do
  expect(unauthorized?).to be true
end

Then(/it is forbidden/) do
  expect(forbidden?).to be true
end

Then(/it is read timeout/) do
  expect(read_timeout?).to be true
end

Then(/it is bad gateway/) do
  expect(bad_gateway?).to be true
end
