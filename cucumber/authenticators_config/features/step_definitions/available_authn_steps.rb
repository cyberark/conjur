# frozen_string_literal: true

When(/I retrieve the list of authenticators/) do
  step "I successfully GET \"/authenticators\""
end

Then(/^the (\S+) authenticators contains "([^"]*)"$/) do |category, value|
  step "the JSON at \"#{category}\" should include \"#{value}\""
end

Then(/^there are exactly (\d+) (\S+) authenticators$/) do |count, category|
  expect(@result[category].length).to be == count
end
