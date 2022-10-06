# frozen_string_literal: true

require 'json'

Given(/^I load a policy:$/) do |policy|
  @client ||= Client.for("user", "admin")
  @result = @client.load_policy(id: 'root', policy: policy)
end

Given(/^I replace the "([^"]*)" policy with:$/) do |policy_id, policy|
  @client ||= Client.for("user", "admin")
  @result = @client.load_policy(id: policy_id, policy: policy)
end

Given(/^I extend the policy with:$/) do |policy|
  @client ||= Client.for("user", "admin")
  @result = @client.replace_policy(id: 'root', policy: policy)
end

Given(/^I update the policy with:$/) do |policy|
  @client ||= Client.for("user", "admin")
  @result = @client.update_policy(id: 'root', policy: policy)
end

Given(/^I try to load a policy with an unresolvable reference:$/) do |policy|
  @client = Client.for("user", "admin")
  @result = @client.load_policy(id: 'root', policy: policy)
  expect(@result.code).to eq(404)
end

Then("the result includes an API key for {string}") do |role_id|
  policy_load_response = JSON.parse(@result)
  expect(policy_load_response.dig('created_roles', role_id, 'api_key')).to be
end
