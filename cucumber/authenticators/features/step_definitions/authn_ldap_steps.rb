# Uses cucumber's multiline string feature: https://bit.ly/2vpzqJx
#
Given(/^a policy:$/) do |policy|
  load_root_policy(policy)
end

# First non-captured group allows for adjectives to clarify the
# purpose of the test.  They aren't actually used.
#
When(/I login via LDAP as (?:\S)+ Conjur user "(\S+)"/) do |username|
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, password: username)
end

When(/my LDAP password for (?:\S)+ Conjur user "(\S+)" is empty/) do |username|
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, password: '')
end



When(/my LDAP password is wrong for authorized user "(\S+)"/) do |username|
  authenticate_with_ldap(service_id: 'test', account: 'cucumber', 
                         username: username, password: 'BAD_PASSWORD')
end

Then(/"(\S+)" is authorized/) do |username|
  expect(token_for(username, @response_body)).to be
end

Then(/it is denied/) do
  expect(authorized?).to be true
end
