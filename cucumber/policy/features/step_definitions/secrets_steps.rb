# frozen_string_literal: true

Then(/^I can( not)? add a secret to ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  @value = SecureRandom.uuid
  status = fail ? 403 : 200
  invoke status: status do
    add_secret(@token, kind, id, @value)
  end
end

Then(/^I can( not)? fetch a secret from ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  expected_status = fail ? 403 : 200
  try_get_secret_value(id, kind, expected_status)
end


Then(/^variable resource "([^"]*)" does not have a secret value$/) do |id|
  expected_status = 404
  try_get_secret_value(id, expected_status)
end

def try_get_secret_value(id, kind = "variable", expected_status)
  invoke status: expected_status do
    get_secret(@token, kind, id)
  end
end
