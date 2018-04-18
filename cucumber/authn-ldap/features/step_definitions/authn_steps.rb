Given(/^a policy:$/) do |string|
  invoke do
    load_root_policy policy
  end
  # pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I can POST "([^"]*)" with plain text body "([^"]*)"$/) do |arg1, arg2|
  pending # Write code here that turns the phrase above into concrete actions
end

#
# Given(/^I create a new user "([^"]*)"$/) do |arg1|
#   pending # Write code here that turns the phrase above into concrete actions
# end
#
# Then(/^I can POST "([^"]*)" with plain text body "([^"]*)"$/) do |arg1, arg2|
#   pending # Write code here that turns the phrase above into concrete actions
# end
#
# When(/^I POST "([^"]*)" with plain text body "([^"]*)"$/) do |arg1, arg2|
#   pending # Write code here that turns the phrase above into concrete actions
# end
#
# Then(/^the HTTP response status code is (\d+)$/) do |arg1|
#   pending # Write code here that turns the phrase above into concrete actions
# end
