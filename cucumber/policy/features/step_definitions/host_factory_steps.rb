# frozen_string_literal: true

Then(/^the "([^"]*)" should be:$/) do |field, json|
  id_array = @result['id'].split(':')
  expect(JSON.parse(get_resource(id_array[1],id_array[2]))[field]).to eq(JSON.parse(json))
end
