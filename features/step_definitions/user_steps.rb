Given(/^a user$/) do
  step "a regular user"
end
  
When(/^a regular user$/) do
  @user = normal_user
end

When(/^a password$/) do
  @user.password = "password"
end

When(/^I use the wrong password$/) do
  @password = "foobar"
end

When(/^I am a super\-user$/) do
  @current_user = admin_user
  expect(@user).to be
  params[:id] = @user.login
end

Given(/^I login as "([^"]*)"$/) do |login|
  @current_user = instance_variable_get("@#{login}")
  expect(@user).to be
  params[:id] = @user.login
end

Given(/^a new user(?: "([^"]*)")?$/) do |login|
  roleid = "cucumber:user:#{user_login(login || 'bob')}"
  user = Role.create id: roleid
  user.grant_to admin_user, admin_option: true
  Resource.create(id: roleid, owner: admin_user)

  if login
    instance_variable_set("@#{login}", user)
  else
    @user = user
  end
end

Given(/^I give "([^"]*)" privilege on the user to "([^"]*)"$/) do |privilege, login|
  @user.resource.permit privilege, Role["cucumber:user:#{user_login login}"]
end

When(/^I( can)? authenticate$/) do |can|
  try_request can do
    RestClient::Resource.new(Conjur::Authn::API.host)["users/#{CGI.escape @user.login}/authenticate"].post(@password || @user.api_key)
  end
end

Given(/^I( can)? update the user using a bearer token$/) do |can|
  try_request can do
    token_auth_request['users'].put(params)
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
    @password = basic_auth_request['users/api_key'].put(params)
  end
end

Then(/^I( can)? rotate the API key using a bearer token$/) do |can|
  try_request can do
    @password = token_auth_request['users/api_key'].put(params)
  end
end

Then(/^I( can)? login$/) do |can|
  try_request can do
    # Don't use API key, we are testing that the password can be used to login
    basic_auth_request(@password || "password")['users/login?' + params.to_query].get
  end
end

Then(/^I( can)? login using a bearer token$/) do |can|
  try_request can do
    token_auth_request['users/login?' + params.to_query].get
  end
end

Then(/^I( can)? show the user$/) do |can|
  try_request can do
    user = JSON.parse(basic_auth_request['users?' + params.to_query].get)
    expect(user['login']).to eq(@user.login)
  end
end

Then(/^I( can)? show the user using a bearer token$/) do |can|
  try_request can do
    user = JSON.parse(token_auth_request['users?' + params.to_query].get)
    expect(user['login']).to eq(@user.login)
  end
end
