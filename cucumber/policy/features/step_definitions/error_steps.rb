# frozen_string_literal: true

Then(/^the error code is "([^"]*)"$/) do |code|
  expect(@error['code']).to eq(code)
end

Then(/^the error message is "([^"]*)"$/) do |message|
  expect(@error['message']).to eq(message)
end

Then(/^the error message includes "([^"]*)"$/) do |message|
  expect(@error['message']).to include(message)
end

Then(/^there is an error$/) do
  expect(json_result).to have_key('error')
  @error = json_result['error']
end

Then(/^there is no error$/) do
  expect(json_result).not_to have_key('error')
end

# The two steps above are the same, but use the 'json_result'
# method to allow any input. The steps should be as
# explicit as possible, and in order to limit scope creep,
# we decided to add additional steps that are used by the policy
# features and refactor the other features at a later date.
# The goal being to remove the two steps above entirely.
Then(/^there's an error$/) do
  expect(@result.body).to have_key('error')
  @error = @result.body['error']
end

Then(/^there's no error$/) do
  expect(@result.body).not_to have_key('error')
end
