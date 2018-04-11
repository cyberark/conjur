Then(/^the result should be "([^"]+)"$/) do |expected|
  expect(@result.to_s).to eq(expected.to_s)
end

Then(/^the result should be the public key$/) do
  expect(@result).to eq(@public_key + "\n")
end
