# frozen_string_literal: true

Then(/^the error code is "([^"]*)"$/) do |code|
puts @error
  expect(@error['code']).to eq(code)
end

Then(/^the error message is "([^"]*)"$/) do |message|
  expect(@error['message']).to eq(message)
end

Then(/^the error message includes "([^"]*)"$/) do |message|
  expect(@error['message']).to include(message)
end

Then(/^there is an error$/) do
  json = json_result
  expect(json).to have_key('error')
  @error = json['error']
end

Then(/^there is no error$/) do
  expect(json_result).not_to have_key('error')
end
