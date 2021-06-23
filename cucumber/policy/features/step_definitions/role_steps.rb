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
