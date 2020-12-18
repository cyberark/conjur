# frozen_string_literal: true

Given(/^I load a policy:$/) do |policy|
  invoke do
    load_root_policy policy
  end
end

Given(/^I replace the "([^"]*)" policy with:$/) do |policy_id, policy|
  invoke do
    load_policy policy_id, policy
  end
end

Given(/^I extend the policy with:$/) do |policy|
  invoke do
    extend_root_policy policy
  end
end

Given(/^I update the policy with:$/) do |policy|
  invoke do
    update_root_policy policy
  end
end

Given(/^I try to load a policy with an unresolvable reference:$/) do |policy|
  invoke status: 404 do
    load_root_policy policy
  end
end

# Stores the policy document to load in a later step
Given(/^a policy document:$/) do |policy_body|
  @policy_body = policy_body
end

Given(/^the policy context:$/) do |policy_context|
  @policy_context = policy_context.raw.to_h
end

When(/^I load the policy into ['"]([^'"]*)['"]$/) do |policy_id|
  invoke do
    load_policy policy_id, @policy_body, context: @policy_context
  end
end
