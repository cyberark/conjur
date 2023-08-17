Then(/^the authenticator status check succeeds$/) do
  expect(@result["status"]).to eq("ok")
end

Then(/^the authenticator status check fails with error "([^"]*)"$/) do |error|
  expect(@result["error"]).to include(error)
end

Then(/^the authenticator status check fails with error matching "([^"]*)"$/) do |error|
  expect(@result["error"]).to match(error)
end
