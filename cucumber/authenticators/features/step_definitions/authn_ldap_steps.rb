# Uses cucumber's multiline string feature: https://bit.ly/2vpzqJx
Given(/^a policy:$/) do |policy|
  load_root_policy(policy)
end


When(/I send an LDAP login for authorized Conjur user "(\S+)"/) do |username|
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, password: username)
end

# When(/I login with valid LDAP credentials for an unauthorized Conjur user/) do
#   'bob'
# end
# When(/I login with valid LDAP credentials for a non-existent Conjur user/) do
#   'NON_EXISTENT_USER'
# end
# When(/I login with invalid LDAP credentials for an authorized Conjur user/) do
#   authenticate_with_ldap('test', 'cucumber', 'alice', 'BAD_PASSWORD')
# end

When(/I get back a valid login token for "(\S+)"/) do |username|
  valid_token_for?(username, @response_body)
end

def authenticate_with_ldap(service_id:, account:, username:, password:)
  path = "/authn-ldap/#{service_id}/#{account}/#{username}/authenticate"
  post(path, password)
end
