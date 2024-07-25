# frozen_string_literal: true

Then(/^the error code is "([^"]*)"$/) do |code|
  expect(@error['code']).to eq(code)
end

Then(/^the error message is "([^"]*)"$/) do |message|
  expect(@error['message']).to eq(message)
end

Then(/^the error message includes "([^"]*)"$/) do |message|
  $stderr.puts("Got message field: #{@error['message']}")
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

Then(/^the policy status is "([^"]*)"$/) do |status|
  expect(@result.body).to have_key('status')
  expect(@result.body['status']).to match(status)
end

Then(/^the policy error includes "([^"]*)"$/) do |message|
  expect(@result.body).to have_key('errors')
  @error = @result.body['errors'][0]
  expect(@error).to have_key('message')
  @policymessage = @error['message']
  expect(@policymessage).to include(message)
end

# Starting with the validation/dry-run feature the error response
# is structured as:
#          "status" => "Invalid YAML",
#          "errors" => [
#            {
#              "line"    => error.line.to_s,
#              "column"  => error.column.to_s,
#              "message" => [error.message.to_s, error.enhanced_message.to_s].join("\n")
#            }
#          ]
# Note: in the initial feature errors[] contains one element.

Then(/^the status is "([^"]*)"$/) do |status|
  @result = json_result
  expect(@result).to have_key('status')
  expect(@result['status']).to match(status)
end

Then(/^there are no errors$/) do
  @result = json_result
  expect(@result).to have_key('errors')
  expect(@result['errors'].length).to be(0)
end

Then(/^the validation error includes "([^"]*)"$/) do |message|
  @result = json_result
  expect(@result).to have_key('errors')
  @message = @result['errors'][0]['message']
  @original = @message.split("\n")
  expect(@original[0]).to include(message)
end

Then(/^the enhanced error includes "([^"]*)"$/) do |message|
  @result = json_result
  expect(@result).to have_key('errors')
  @message = @result['errors'][0]['message']
  @messages = @message.split("\n")
  @enhanced = @messages[1, @messages.length].join(' ')
  expect(@enhanced).to include(message)
end
