# frozen_string_literal: true
require 'cucumber/policy/features/support/client'
require 'json'

Then('the list of authenticators contains the service-id {string}') do |service_id|
  @client ||= Client.for("user", "admin")
  @result = @client.fetch_authenticators
  puts @result.body
  expect(@result.code).to eq(200)

  expect(
    @result.body.map { |x| x["name"] }
  ).to include("authn-oidc/#{service_id}")
end

Then('I can fetch the authenticator by its service-id {string}') do |service_id|
  @client ||= Client.for("user", "admin")
  @result = @client.fetch_authenticator(id: service_id)
  expect(@result.code).to eq(200)
  expect(
    @result.body["redirect_uri"]
  ).to_not eq({})
end

Then('it will return an empty array for {string}') do |service_id|
  @client ||= Client.for("user", "admin")
  @result = @client.fetch_authenticator(id: service_id)
  expect(@result.code).to eq(200)
  expect(@result.body).to eq({})
end
