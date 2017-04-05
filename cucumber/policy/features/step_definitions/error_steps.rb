Then(/^the error code is "([^"]*)"$/) do |code|
  expect(@error['code']).to eq(code)
end

Then(/^the error message is "([^"]*)"$/) do |message|
  expect(@error['message']).to eq(message)
end
