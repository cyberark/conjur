Then(/^the result is:$/) do |string|
  expect(result).to eq(string)
end
