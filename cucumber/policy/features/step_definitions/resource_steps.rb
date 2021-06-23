# frozen_string_literal: true

Then(/^([\w_]+) "([^"]*)" exists$/) do |kind, id|
  @client = Client.for("user", "admin")
  expect(@client.fetch_resource(kind: kind, id: id).code).to be < 300
end

Then(/^([\w_]+) "([^"]*)" does not exist$/) do |kind, id|
  expect(@client.fetch_resource(kind: kind, id: id).code).to be >= 300
end

Then(/^there is a ([\w_]+) resource "([^"]*)"$/) do |kind, id|
  @result = @client.fetch_resource(kind: kind, id: id)
end

When(/^I list the roles permitted to (\w+) ([\w_]+) "([^"]*)"$/) do |privilege, kind, id|
  @client = Client.for("user", "admin")
  @result =
    @client.fetch_roles_with_privilege(kind: kind, id: id, privilege: privilege)

  # Save this state because future steps need it.
  @privilege = privilege
end

Then(/^the role list includes ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(@result.body).to include(make_full_id(kind, id))
end

Then(/^the role list does not include ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(@result.body).to_not include(make_full_id(kind, id))
end

When(/^I list ([\w_]+) resources$/) do |kind|
  @client ||= Client.for("user", "admin")
  @result = @client.fetch_resource(kind: kind, id: nil)
end

Then(/^the resource list includes ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(
    @result.body.map { |x| x["id"] }
  ).to include(make_full_id(kind, id))
end

Then(/^the owner of ([\w_]+) "([^"]*)" is ([\w_]+) "([^"]*)"$/) do |object_kind, object_id, owner_kind, owner_id|
  @client ||= Client.for("user", "admin")
  @result = @client.fetch_resource(kind: object_kind, id: object_id)
  expect(@result.body["owner"]).to eq(
    make_full_id(owner_kind, owner_id)
  )
end
