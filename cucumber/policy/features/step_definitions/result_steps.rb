# frozen_string_literal: true

Then(/^the result is:$/) do |string|
  expect(@result).to eq(string)
end

Then(/^the result should not contain:$/) do |string|
  expect(@result).to_not include(string)
end
