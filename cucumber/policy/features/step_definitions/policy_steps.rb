Given(/^a policy:$/) do |policy|
  load_root_policy policy
end

Given(/^I load policy "([^"]*)":$/) do |policy_id, policy|
  load_policy policy_id, policy
end

Given(/^I extend the policy with:$/) do |policy|
  extend_root_policy policy
end

Given(/^I update the policy with:$/) do |policy|
  update_root_policy policy
end

Given(/^I try to load a policy with an unresolvable reference:$/) do |policy|
  invoke status: 404 do
    load_root_policy policy
  end
  result = JSON.parse(@exception.response.body)
  expect(result).to have_key('error')
  @error = result['error']
end
