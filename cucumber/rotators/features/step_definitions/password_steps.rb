Then(/^I create a db user "(.*?)" with password "(.*?)"$/) do |user, pw|
  # drop them first, in case we're re-running during dev
  run_sql_in_testdb("DROP DATABASE #{user};")
  run_sql_in_testdb("DROP USER #{user};")
  run_sql_in_testdb("CREATE USER #{user} WITH PASSWORD '#{pw}';")
  run_sql_in_testdb("CREATE DATABASE #{user};")
end

# Then(/^I can(not)? login with user "(.+)" and password "(.*)"$/) do |deny, user, pw|
#   expected_result = deny ? false : true
#   result = system("PGPASSWORD=#{pw} psql -c \"\\q\" -h #{pg_host} -U #{user}")
#   expect(result).to be expected_result
# end

Then(/^the db password for "(.*)" is "(.*)"$/) do |user, pw|
  good_pw_result = pg_login_result(user, pw)
  bad_pw_result  = pg_login_result(user, 'WRONG_PASSWORD')
  expect(good_pw_result).to be true
  expect(bad_pw_result).to be false
end

Then(/^I watch for changes in "(.+)" and db user "(.+)"$/) do |var_id, user|
  start_polling_for_changes(var_id, user)
end

Then(/^I stop watching for changes$/) do
  stop_polling_for_changes
end

Then(/^the first (\d+) db and conjur passwords match$/) do |num_str|
  num        = num_str.to_i
  db_pws     = db_passwords.first(num)
  conjur_pws = conjur_passwords.first(num)
  puts 'db_pws', db_pws
  expect(db_pws).to match_array(conjur_pws)
end

Given(/^I have the root policy:$/) do |policy|
  invoke do
    load_root_policy policy
  end
end

# versions = (1..var.version_count).map do |version|
#   var.value version
# end

Given(/^I reset my root policy$/) do
  invoke do
    load_root_policy <<~EOS
      - !policy
         id: db-reports
         body:
    EOS
  end
end

Given(/^I add the value "(.*)" to variable "(.+)"$/) do |val, var|
  variable = variable_resource(var)
  variable.add_value(val)
end

Then(/^the "(.*)" variable is "(.*)"$/) do |var, val|
  variable = variable_resource(var)
  expect(variable.value).to eq val
end

Then(/^the "(.*)" variable is not "(.*)"$/) do |var, val|
  variable = variable_resource(var)
  expect(variable.value).not_to eq val
end

Then(/^I wait for (\d+) seconds?$/) do |num_seconds|
  puts "Sleeping #{num_seconds}...."
  sleep(num_seconds.to_i)
end
