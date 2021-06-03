# frozen_string_literal: true

Then(/^the "([^"]*)" should be:$/) do |field, json|
  _, kind, id = @result['id'].split(':')
  actual = JSON.parse(get_resource(kind, id))[field]
  expected = JSON.parse(json)
  expect(actual).to eq(expected)
end
