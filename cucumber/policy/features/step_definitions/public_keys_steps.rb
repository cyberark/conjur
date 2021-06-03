# frozen_string_literal: true

Then(/^I list the public keys for "([^"]*)"$/) do |username|
  invoke do
    RestClient.get(uri('public_keys', 'user', username))
  end
end
