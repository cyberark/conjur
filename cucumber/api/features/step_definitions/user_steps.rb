# frozen_string_literal: true

When(/^I am the super\-user$/) do
  @current_user = admin_user
end

When(/^I am a user named "([^"]*)"$/) do |login|
  @current_user = create_user(login, admin_user)
end

Given(/^I create a new user "([^"]*)"$/) do |login|
  create_user login, @current_user || admin_user
end

Given(/^I create a new admin-owned user "(.*?)"$/) do |login|
  create_user login, admin_user
end

Given(/^I create a new user "([^"]*)" in account "([^"]*)"$/) do |login, account|
  roleid = "#{account}:user:#{login}"
  Role.create(role_id: roleid)
end

When(/^I operate on "([^"]*)"$/) do |login|
  @current_user = lookup_user(login)
end

Given(/^I login as "([^"]*)"$/) do |login|
  roleid = if login.include?(":")
    login
  else
    "cucumber:user:#{login}"
  end

  @current_user = Role.with_pk!(roleid)
  Credentials.new(role: @current_user).save unless @current_user.credentials
end

Given(/^I log out$/) do
  @current_user =  nil
end
  
When(/^I have a password$/) do
  @current_user.password = "password"
  @current_user.save
end

Given(/^I set the password for "([^"]*)" to "([^"]*)"$/) do |login, password|
  user = lookup_user(login)
  user.password = password
  user.save
end

When(/^I use the wrong password$/) do
  @password = "foobar"
end

When(/^I( can)? authenticate$/) do |can|
  try_request can do
    RestClient::Resource.new(Conjur::Authn::API.host)["users/#{CGI.escape @current_user.login}/authenticate"].post(@password || @current_user.api_key)
  end
end

Given(/^I( can)? update the user using a bearer token$/) do |can|
  try_request can do
    token_auth_request['users'].put(authn_params)
  end
end

Then(/^I( can)? change the password using a bearer token$/) do |can|
  try_request can do
    token_auth_request['users/password'].put("foobar")
  end
end

Then(/^I( can)? change the password$/) do |can|
  try_request can do
    @password = "foobar"
    basic_auth_request['users/password'].put(@password)
  end
end

Then(/^I( can)? rotate the API key$/) do |can|
  try_request can do
    @password = basic_auth_request['users/api_key'].put(authn_params)
  end
end

Then(/^I( can)? rotate the API key using a bearer token$/) do |can|
  try_request can do
    @password = token_auth_request['users/api_key'].put(authn_params)
  end
end

Then(/^I( can)? login$/) do |can|
  try_request can do
    # Don't use API key, we are testing that the password can be used to login
    basic_auth_request(@password || "password")['users/login?' + authn_params.to_query].get
  end
end

Then(/^I( can)? login using a bearer token$/) do |can|
  try_request can do
    token_auth_request['users/login?' + authn_params.to_query].get
  end
end
