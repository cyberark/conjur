# frozen_string_literal: true

# Uses cucumber's multiline string feature: https://bit.ly/2vpzqJx
#

When(/I login via( secure)? LDAP as (?:\S)+ Conjur user "(\S+)"/) do |secure, username|
  service_id = secure ? 'secure' : 'test'
  login_with_ldap(service_id: service_id, account: 'cucumber', 
                  username: username, password: username)
end

# First non-captured group allows for adjectives to clarify the
# purpose of the test.  They aren't actually used.
#
When(/I authenticate via( secure)? LDAP as (?:\S)+ Conjur user "(\S+)"( using key)?/) do |secure, username, using_key|
  password = using_key ? ldap_auth_key : username
  service_id = secure ? 'secure' : 'test'
  authenticate_with_ldap(service_id: service_id, account: 'cucumber', 
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

Given(/^I store the LDAP bind password in "([^"]*)"$/) do |variable_name|
  save_variable_value('cucumber', variable_name, 'ldapsecret')
end

Given(/^I store the LDAP CA certificate in "([^"]*)"$/) do |variable_name|
  save_variable_value('cucumber', variable_name, ldap_ca_certificate_value)
end
