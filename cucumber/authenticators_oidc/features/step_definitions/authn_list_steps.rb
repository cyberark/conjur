# frozen_string_literal: true

require 'cucumber/policy/features/support/client'
require 'json'

Then('the list of authenticators contains the service-id {string}') do |service_id|
  @result = @client.fetch_authenticators
  expect(@result.code).to eq(200)
  expect(
    @result.body.map { |x| x["service_id"] }
  ).to include(service_id)
end


Then('the list of authenticators does not contain the service-id {string}') do |service_id|
  @result = @client.fetch_authenticators
  expect(@result.code).to eq(200)
  expect(
    @result.body.map { |x| x["service_id"] }
  ).not_to include(service_id)
end
