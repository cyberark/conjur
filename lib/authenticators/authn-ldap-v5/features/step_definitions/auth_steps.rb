require 'conjur/api'
require 'restclient'

When(/^I authenticate as "([^"]*)"$/) do |login|
  @password ||= login
  begin
    @token = ConjurToken.new(
      RestClient.post("http://authn-ldap/users/#{login}/authenticate", @password))
  rescue RestClient::Exception => e
    @exception = e
  end
end

Then(/^I get a token for "([^"]*)"$/) do |login|
  expect(@exception).to be_nil
  expect(@token.login).to eq(login)
end

When(/^I use the empty string as the password$/) do
  @password = ""
end

When(/^I use password "([^"]*)"$/) do |password|
  @password = password
end

When(/^the password is incorrect$/) do
  @password = "foobar"
end

Then(/^it is denied$/) do
  expect(@exception).to be
  expect(@exception).to be_instance_of(RestClient::Unauthorized)
end

When(/^I enable logging$/) do
  ENV['LOG_LEVEL'] = 'debug'
end
