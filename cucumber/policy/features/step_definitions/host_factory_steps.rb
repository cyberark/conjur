# frozen_string_literal: true

Then(/^the "([^"]*)" should be:$/) do |field, json|
  expect(@result[field]).to eq(JSON.parse(json))
end
