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
