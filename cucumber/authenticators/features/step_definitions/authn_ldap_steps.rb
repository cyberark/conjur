# frozen_string_literal: true

# First non-captured group allows for adjectives to clarify the
# purpose of the test.  They aren't actually used.
#
When(/I authenticate via LDAP as (?:\S)+ Conjur user "(\S+)"/) do |username|
  password = username
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, password: password)
end

When(/my LDAP password for (?:\S)+ Conjur user "(\S+)" is empty/) do |username|
  password = ""
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
    username: username, password: password)
end

When(/my LDAP password is wrong for authorized user "(\S+)"/) do |username|
  password = "bad_password"
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
    username: username, password: password)
end

Then(/it is denied/) do
  expect(unauthorized?).to be true
end

Then(/it is forbidden/) do
  expect(forbidden?).to be true
end
