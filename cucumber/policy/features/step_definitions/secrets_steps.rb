# frozen_string_literal: true

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then(/^I can( not)? add a secret to ([\w_]+) resource "([^"]*)"$/) do |fail, _kind, id|
  @random_secret = SecureRandom.uuid
  expected_status = fail ? 403 : 201
  resp = @client.add_secret(id: id, value: @random_secret)
  expect(resp.code).to eq(expected_status)
end

When(/^I add a secret to ([\w_]+) resource "([^"]*)"$/) do |_kind, id|
  @random_secret = SecureRandom.uuid
  @resp = @client.add_secret(id: id, value: @random_secret)
end

Then(/^The response status code is (\d+)$/) do |code|
  expect(@resp.code).to eq(401)
end

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then(/^I can( not)? add a provider-url to ([\w_]+) resource "([^"]*)"$/) do |fail, _kind, id|
  expected_status = fail ? 403 : 201
  @oidc_provider_uri ||= validated_env_var('PROVIDER_URI')
  resp = @client.add_secret(id: id, value: @oidc_provider_uri)
  expect(resp.code).to eq(expected_status)
end

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then('I can add the secret {string} resource {string}') do |value, id|
  resp = @client.add_secret(id: id, value: value)
  expect(resp.code).to eq(201)
end

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then(/^I can( not)? fetch a secret from ([\w_]+) resource "([^"]*)"$/) do |fail, _kind, id|
  expected_status = fail ? 403 : 200
  resp = @client.fetch_secret(id: id)
  expect(resp.code).to eq(expected_status)
end

Then("I can retrieve the same secret value from {string}") do |id|
  resp = @client.fetch_secret(id: id)
  expect(resp.code).to eq(200)
  expect(resp.body).to eq(@random_secret)
end

Then(/^variable resource "([^"]*)" does not have a secret value$/) do |id|
  resp = @client.fetch_secret(id: id)
  expect(resp.code).to eq(404)
end