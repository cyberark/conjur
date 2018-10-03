Given(/^a policy:$/) do |policy|
  load_root_policy(policy)
end

Then(/"(\S+)" is authorized/) do |username|
  expect(token_for(username, @response_body)).to be
end
