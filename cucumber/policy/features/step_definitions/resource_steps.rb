# frozen_string_literal: true

Then(/^([\w_]+) "([^"]*)" exists$/) do |kind, id|
  expect(conjur_api.resource(make_full_id(kind, id))).to exist
end

Then(/^([\w_]+) "([^"]*)" does not exist$/) do |kind, id|
  expect(conjur_api.resource(make_full_id(kind, id))).to_not exist
end

Then(/^there is a ([\w_]+) resource "([^"]*)"$/) do |kind, id|
  invoke do
    conjur_api.resource(make_full_id(kind, id))
  end
end

When(/^I list the roles permitted to (\w+) ([\w_]+) "([^"]*)"$/) do |privilege, kind, id|
  invoke do
    conjur_api.resource(make_full_id(kind, id)).permitted_roles(privilege)
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
    conjur_api.resources(kind: kind)
  end
end

Then(/^the resource list includes ([\w_]+) "([^"]*)"$/) do |kind, id|
  expect(result.map(&:id)).to include(make_full_id(kind, id))
end

Then(/^the owner of ([\w_]+) "([^"]*)" is ([\w_]+) "([^"]*)"$/) do |object_kind, object_id, owner_kind, owner_id|
  expect(conjur_api.resource(make_full_id(object_kind, object_id)).owner.id).to eq(make_full_id(owner_kind, owner_id))
end
