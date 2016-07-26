Then(/^it's confirmed$/) do
  expect(@status).to be_blank
end

Then(/^it's not authenticated$/) do
  expect(@status).to eq(401)
end

Then(/^it's forbidden$/) do
  expect(@status).to eq(403)
end

Then(/^it's not found$/) do
  expect(@status).to eq(404)
end

Then(/^the result is true$/) do
  expect(@result).to be true
end

Then(/^the result is false$/) do
  expect(@result).to be false
end
