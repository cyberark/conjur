Then(/^the result should be "([^"]+)"$/) do |expected|
  expect(@result.to_s).to eq(expected.to_s)
end
