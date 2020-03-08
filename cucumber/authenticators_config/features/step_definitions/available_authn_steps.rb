# frozen_string_literal: true

When(/I retrieve the list of authenticators/) do
  step "I successfully GET \"/authenticators\""
end

Then(/^the (\S+) authenticators contains "([^"]*)"$/) do |category, value|
  step "the JSON at \"#{category}\" should include \"#{value}\""
end
