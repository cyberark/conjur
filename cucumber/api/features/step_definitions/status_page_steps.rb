# frozen_string_literal: true

When(/^I GET the root route$/) do
  @response = RestClient.get(Conjur.configuration.appliance_url)
end

When(/^I GET the root route with JSON$/) do
  @response = RestClient.get(Conjur.configuration.appliance_url, accept: :json)
end

Then(/^the status page is reachable$/) do
  expect(@response.code).to eq(200)
  expect(@response.headers[:content_type]).to include("text/html")
  expect(@response.body).to include("is running!")
end

Then(/^the status JSON includes the version number$/) do
  expect(@response.code).to eq(200)
  expect(@response.headers[:content_type]).to include("application/json")

  version = File.read(File.expand_path("../../../../VERSION", File.dirname(__FILE__)))
  expect(@response.body).to include("\"version\":\"#{version}\"")
end
