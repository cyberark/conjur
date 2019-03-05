Then(/"(\S+)" is authorized/) do |username|
  expect(token_for(username, @response_body)).to be
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(["user_name","expiration_time","id_token_encrypted"], @response_body)).to be
end

# TODO: find a good way to share steps between cucumber profiles
Given(/^a policy:$/) do |policy|
  load_root_policy(policy)
end

Given(/^I add the secret value(?: "([^"]*)")? to the resource(?: "([^"]*)")?$/) do |value, resource_id|
  Secret.create resource_id: resource_id, value: value
end