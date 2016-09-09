Given(/^a policy:$/) do |policy|
  load_bootstrap_policy policy
end

Given(/^I load policy "([^"]*)":$/) do |policy_id, policy|
  load_policy policy_id, policy
end
