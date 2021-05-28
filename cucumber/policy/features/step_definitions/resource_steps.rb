# frozen_string_literal: true

Then(/^([\w_]+) "([^"]*)" exists$/) do |kind, id|
  expect { get_resource(kind, id) }.to_not raise_error
end

Then(/^([\w_]+) "([^"]*)" does not exist$/) do |kind, id|
  expect { get_resource(kind, id) }.to raise_error
end

Then(/^there is a ([\w_]+) resource "([^"]*)"$/) do |kind, id|
  invoke do
    get_resource(kind, id)
  end
end

When(/^I list the roles permitted to (\w+) ([\w_]+) "([^"]*)"$/) do |privilege, kind, id|
  invoke do
    get_privilaged_roles(kind, id, privilege)
  end
end

Then(/^the role list includes ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(result).to include(make_full_id(kind, id))
end

Then(/^the role list does not include ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(result).to_not include(make_full_id(kind, id))
end

When(/^I list ([\w_]+) resources$/) do |kind|
  invoke do
    get_resource(kind, '').body
  end
end

Then(/^the resource list includes ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(JSON.parse(result).map{|x| x["id"]}).to include(make_full_id(kind, id))
end

Then(/^the owner of ([\w_]+) "([^"]*)" is ([\w_]+) "([^"]*)"$/) do |object_kind, object_id, owner_kind, owner_id|
  expect(JSON.parse(get_resource(object_kind, object_id))["owner"]).to eq(make_full_id(owner_kind, owner_id))
end
