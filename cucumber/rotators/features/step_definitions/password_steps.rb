Then(/^I create a postgres user "(.*?)" with password "(.*?)"$/) do |user, pw|
  # drop them first, in case we're re-running during dev
  run_sql_in_testdb("DROP DATABASE #{user};")
  run_sql_in_testdb("DROP USER #{user};")
  run_sql_in_testdb("CREATE USER #{user} WITH PASSWORD '#{pw}';")
  run_sql_in_testdb("CREATE DATABASE #{user};")
end

Then(/^I can(not)? login with user "(.+)" and password "(.*)"$/) do |deny, user, pw|
  expected_result = deny ? false : true
  result = system("PPASSWORD=#{pw} psql -c \"\\q\" -h #{pg_host} -U #{user}")
  expect(result).to be expected_result
end

# Then /^I create a postgres password variable "(.*?)" for user "(.*?)" with value "(.*?)"$/ do |var, username, value|
#   prefix = var.match(%r{(.*)/.*})[1]
#   steps %Q{
#     When I create a rotating variable "#{var}" with rotator "postgresql/password" ttl "P1D" and value "#{value}"
#     And I successfully run `conjur variable create --as-group security_admin #{prefix}/username #{username}`
#     And I successfully run `conjur variable create --as-group security_admin #{prefix}/url #{ENV['PGHOST']}/#{username}`
#   }
# end
