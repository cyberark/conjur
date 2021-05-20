# frozen_string_literal: true

Then(/^I list the public keys for "([^"]*)"$/) do |username|
  invoke do
    RestClient.get(appliance_url() + '/public_keys/' + account() + '/user/' + username)
  end
end
