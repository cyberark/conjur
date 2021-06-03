# frozen_string_literal: true

Then(/^([\w_]+) "([^"]*)" is a role member( with admin option)?$/) do |role_kind, role_id, admin|
  members = @result['members']
  if admin
    members = members.select{|m| m["member"]}
  end
  expect(members.map{|x| x["member"]}).to include(make_full_id(role_kind, role_id))
end

Then(/^([\w_]+) "([^"]*)" is not a role member$/) do |role_kind, role_id|
  members = @result['members']
  expect(members.map{|x| x["member"]}).to_not include(make_full_id(role_kind, role_id))
end
