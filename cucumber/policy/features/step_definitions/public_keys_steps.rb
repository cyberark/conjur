# frozen_string_literal: true

Then(/^I list the public keys for "([^"]*)"$/) do |username|
  invoke do
    Conjur::API.public_keys(username)
  end
end
