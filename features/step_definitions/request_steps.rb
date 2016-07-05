Then(/^it's not authenticated$/) do
  expect(@status).to eq(401)
end

Then(/^it's forbidden$/) do
  expect(@status).to eq(403)
end

Then(/^it's not found$/) do
  expect(@status).to eq(404)
end
