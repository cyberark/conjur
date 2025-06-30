Given(/^I obtain a valid IAM identity token$/) do
  iam_identity_access_token
end

Given(/I authenticate with authn-iam using a valid identity token for "([^"]*)"/) do |username|
  authenticate_iam_token(username)
end