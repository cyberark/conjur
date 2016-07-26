Given(/^I check if I can "([^"]*)" on "([^"]*)"$/) do |privilege, resource|
  invoke do
    possum.resource_check resource, privilege
  end
end

When(/^I list the roles permitted to (\w+) (\w+) "([^"]*)"$/) do |privilege, kind, id|
  invoke do
    possum.resource_permitted_roles [ kind, id ].join(":"), privilege
  end
end

Then(/^the role list includes (\w+) "([^"]*)"$/) do |kind, id|
  expect(result).to include(make_full_id(kind, id))
end

When(/^I list "([^"]*)" resources$/) do |kind|
  invoke do
    possum.resource_list kind: kind
  end
end

Then(/^the resource list includes (\w+) "([^"]*)"$/) do |kind, id|
  expect(result.map{|r| r['id']}).to include(make_full_id(kind, id))
end
