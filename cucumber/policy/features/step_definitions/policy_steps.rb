Given(/^a policy:$/) do |policy|
  load_root_policy policy
end

Given(/^I load policy "([^"]*)":$/) do |policy_id, policy|
  load_policy policy_id, policy
end

Given(/^I replace the policy by loading the policy file "([^"]*)"$/) do |policy_file|
  policy = load_policy_from_file policy_file
  invoke do
    load_root_policy policy
  end
end

When(/^I replace the policy by loading the concatenated policy files "([^"]*)"$/) do |file_list|
  policy = ''
  files = file_list.split(" ")
  files.each do |file|
    policy += load_policy_from_file file
  end
  invoke do
    data = load_root_policy policy
  end
end

Given(/^I load a "([^"]*)" policy file "([^"]*)"$/) do |policy_id, policy_file|
  policy = load_policy_from_file policy_file
  invoke do
    extend_policy policy_id, policy
  end
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
  expect(json_result).to have_key('error')
  @error = @result['error']
end
