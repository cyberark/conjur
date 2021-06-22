# frozen_string_literal: true

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then(/^I can( not)? add a secret to ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  @random_secret = SecureRandom.uuid
  expected_status = fail ? 403 : 201
  resp = api_response { @client.add_secret(id: id, value: @random_secret) }
  expect(resp.code).to eq(expected_status)
end

# TODO: kind is now superfluous.  It is never used, since it's always "variable"
Then(/^I can( not)? fetch a secret from ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  expected_status = fail ? 403 : 200
  resp = api_response { @client.fetch_secret(id: id) }
  expect(resp.code).to eq(expected_status)
end

Then("I can retrieve the same secret value from {string}") do |id|
  resp = api_response { @client.fetch_secret(id: id) }
  expect(resp.code).to eq(200)
  expect(resp.body).to eq(@random_secret)
end

Then(/^variable resource "([^"]*)" does not have a secret value$/) do |id|
  resp = api_response { @client.fetch_secret(id: id) }
  expect(resp.code).to eq(404)
end
