Given(/^a policy:$/) do |policy|
  load_bootstrap_policy policy
end

Given(/^I load policy "([^"]*)":$/) do |policy_id, policy|
  load_policy policy_id, policy
end

Given(/^I extend the policy with:$/) do |policy|
  extend_bootstrap_policy policy
end

Given(/^I try to load the policy:$/) do |policy|
  response = possum.client.client.put "policies/cucumber/policy/bootstrap", policy
  expect(response.status).to be >= 400
  @error = response.body
  expect(@error).to be_instance_of(Hash)
  expect(@error).to have_key('error')
  @error = @error['error']
end
