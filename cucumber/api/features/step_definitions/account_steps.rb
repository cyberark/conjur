Given(/^the accounts resource exists$/) do
  Account.find_or_create_accounts_resource
end
