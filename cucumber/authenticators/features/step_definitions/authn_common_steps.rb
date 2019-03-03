require_relative '../../../../cucumber/api/features/step_definitions/authz_steps'

Given(/^a policy:$/) do |policy|
  load_root_policy(policy)
end

Then(/"(\S+)" is authorized/) do |username|
  expect(token_for(username, @response_body)).to be
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(["user_name","expiration_time","id_token_encrypted"], @response_body)).to be
end
