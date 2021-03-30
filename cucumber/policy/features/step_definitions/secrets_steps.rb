# frozen_string_literal: true

Then(/^I can( not)? add a secret to ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  @value = SecureRandom.uuid
  status = fail ? 403 : 200
  invoke status: status do
    conjur_api.resource(make_full_id(kind, id)).add_value(@value)
  end
end

Then(/^I can( not)? fetch a secret from ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  status = fail ? 403 : 200
  invoke status: status do
    conjur_api.resource(make_full_id(kind, id)).value
  end
end
