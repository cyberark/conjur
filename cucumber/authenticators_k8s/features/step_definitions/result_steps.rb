Then(/^the HTTP status is "([^"]*)"$/) do |code|
  expect(@error).to be
  expect(@error.http_code).to eq(code.to_i)
end
