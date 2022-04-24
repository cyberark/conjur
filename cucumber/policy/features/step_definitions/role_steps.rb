# frozen_string_literal: true

Then("{word} {string} is a role member") do |kind, id|
  members = @result.body['members'].map { |x| x['member'] }
  expect(members).to include(make_full_id(kind, id))
end

Then("{word} {string} is a role member with admin option") do |kind, id|
  members =
    @result.body['members'].select { |x| x['admin_option'] }.map { |x| x['member'] }
  expect(members).to include(make_full_id(kind, id))
end

Then("{word} {string} is not a role member") do |kind, id|
  members = @result.body['members'].map { |x| x['member'] }
  expect(members).to_not include(make_full_id(kind, id))
end

Then('no role record exists for {string}') do |role_id|
  expect(Role.where(role_id: "cucumber:host:#{role_id}").count).to eq(0)
end

Then('no credentials records exist for {string}') do |role_id|
  expect(Credentials.where(role_id: "cucumber:host:#{role_id}").count).to eq(0)
end

Then('no permission records exist for {string}') do |role_id|
  expect(Permission.where(role_id: "cucumber:host:#{role_id}").count).to eq(0)
end

Then('no membership records exist for {string}') do |role_id|
  expect(RoleMembership.where(member_id: "cucumber:host:#{role_id}").count).to eq(0)
end
