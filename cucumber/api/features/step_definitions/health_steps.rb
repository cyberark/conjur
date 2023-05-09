# frozen_string_literal: true

When(/^I GET the health route$/) do
  @response = RestClient.get(Conjur.configuration.appliance_url + "/health")
end

Then(/^the health route is reachable$/) do
  expect(@response.code).to eq(200)
end
