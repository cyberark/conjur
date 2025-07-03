# frozen_string_literal: true

# Uses cucumber's multiline string feature: https://bit.ly/2vpzqJx
#

When(/I login via ([^"]*) LDAP as (?:\S)+ Conjur user "(\S+)"/) do |service_id, username|
  login_with_ldap(service_id: service_id, account: 'cucumber', 
                  username: username, password: username)
end

# First non-captured group allows for adjectives to clarify the
# purpose of the test.  They aren't actually used.
#
When(/I authenticate via ([^"]*) LDAP as (?:\S)+ Conjur user "(\S+)"( using key)?/) do |service_id, username, using_key|
  password = using_key ? ldap_auth_key : username
  authenticate_with_ldap(service_id: service_id, account: 'cucumber', 
                         username: username, api_key: password)
end

When(/my LDAP password for (?:\S)+ Conjur user "(\S+)" is empty/) do |username|
  login_with_ldap(service_id: 'test', account: 'cucumber', 
                  username: username, password: '')
end

When(/my LDAP password is wrong for authorized user "(\S+)"/) do |username|
  login_with_ldap(service_id: 'test', account: 'cucumber', 
                  # file deepcode ignore HardcodedPassword: This is a test code, not an actual credential
                  username: username, password: 'BAD_PASSWORD')
end

Given(/^I store the LDAP bind password in "([^"]*)"$/) do |variable_name|
  save_variable_value('cucumber', variable_name, 'ldapsecret')
end

Given(/^I store the LDAP CA certificate in "([^"]*)"$/) do |variable_name|
  save_variable_value('cucumber', variable_name, ldap_ca_certificate_value)
end

Given(/^I successfully initialize an LDAP authenticator named "([^"]*)" via the authenticators API$/) do |service_id|
  path = "#{conjur_hostname}/authenticators/#{ENV['CONJUR_ACCOUNT']}"
  payload = {
    type: "ldap",
    name: service_id,
    enabled: true
  }

  post(path, payload.to_json, authenticated_v2_api_headers)
end

Given(/^I successfully initialize an LDAP authenticator named "([^"]*)" using variables via the authenticators API$/) do |service_id|
  path = "#{conjur_hostname}/authenticators/#{ENV['CONJUR_ACCOUNT']}"
  payload = {
    type: "ldap",
    name: service_id,
    enabled: true,
    data: {
      bind_password: 'ldapsecret',
      tls_ca_cert: ldap_ca_certificate_value
    },
    annotations: {
      "ldap-authn/base_dn": "dc=conjur,dc=net",
      "ldap-authn/bind_dn": "cn=admin,dc=conjur,dc=net",
      "ldap-authn/connect_type": "tls",
      "ldap-authn/host": "ldap-server",
      "ldap-authn/port": "389",
      "ldap-authn/filter_template": "(uid=%s)"
    }
  }

  post(path, payload.to_json, authenticated_v2_api_headers)
end
