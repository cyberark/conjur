# frozen_string_literal: true

# Uses cucumber's multiline string feature: https://bit.ly/2vpzqJx
#

When(/I login via LDAP as (?:\S)+ Conjur user "(\S+)"/) do |username|
  login_with_ldap(service_id: 'test', account: 'cucumber', 
                  username: username, password: username)
end

# First non-captured group allows for adjectives to clarify the
# purpose of the test.  They aren't actually used.
#
When(/I authenticate via LDAP as (?:\S)+ Conjur user "(\S+)"( using key)?/) do |username, using_key|
  password = using_key ? ldap_auth_key : username
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, api_key: password)
end

When(/my LDAP password for (?:\S)+ Conjur user "(\S+)" is empty/) do |username|
  login_with_ldap(service_id: 'test', account: 'cucumber', 
                  username: username, password: '')
end



When(/my LDAP password is wrong for authorized user "(\S+)"/) do |username|
  login_with_ldap(service_id: 'test', account: 'cucumber', 
                  username: username, password: 'BAD_PASSWORD')
end

Then(/it is denied/) do
  expect(unauthorized?).to be true
end

Then(/it is forbidden/) do
  expect(forbidden?).to be true
end
