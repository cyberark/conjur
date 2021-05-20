# frozen_string_literal: true

Then(/^I list the public keys for "([^"]*)"$/) do |username|
  invoke do
    RestClient.get('http://localhost:3000/public_keys/cucumber/user/' + username)
  end
end
