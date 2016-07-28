When(/^I( (?:can|successfully))? GET "([^"]*)"$/) do |can, path|
  try_request can do
    get_json path
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)"$/) do |can, path|
  try_request can do
    put_json path
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with parameters:$/) do |can, path, parameters|
  params = YAML.load(parameters)
  path = [ path, params.to_query ].join("?")
  try_request can do
    get_json path
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with(?: username "([^"]*)" and password "([^"]*)")?(?: and)?(?: plain text body "([^"]*)")?$/) do |can, path, username, password, body|
  try_request can do
    put_json path, body, user: username, password: password
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with username "([^"]*)" and password "([^"]*)"$/) do |can, path, username, password|
  try_request can do
    get_json path, user: username, password: password
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)"(?: with plain text body "([^"]*)")?$/) do |can, path, body|
  try_request can do
    post_json path, body
  end
end

Then(/^the result is an API key$/) do
  expect(@result).to be
  expect(@result.length).to be > 40
  expect(@result).to match(/^[a-z0-9]+$/)
end

Then(/^the result is the API key for user "([^"]*)"$/) do |login|
  user = lookup_user(login)
  user.reload
  expect(user.credentials).to be
  expect(@result).to eq(user.credentials.api_key)
end

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
