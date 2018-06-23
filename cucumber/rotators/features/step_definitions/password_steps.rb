Then(/^I create a db user "(.*?)" with password "(.*?)"$/) do |user, pw|
  # drop them first, in case we're re-running during dev
  run_sql_in_testdb("DROP DATABASE #{user};")
  run_sql_in_testdb("DROP USER #{user};")
  run_sql_in_testdb("CREATE USER #{user} WITH PASSWORD '#{pw}';")
  run_sql_in_testdb("CREATE DATABASE #{user};")
end

re = /^I poll "(.+)" and db user "(.+)" for (\d+) rotations in (\d+) seconds$/
Then(re) do |var, user, num_rots_str, timeout_str|
  poll_for_N_rotations(
    var_id: var,
    db_user: user,
    num_rots: num_rots_str.to_i,
    timeout: timeout_str.to_i
  )
end

Then(/^the first (\d+) db and conjur passwords match$/) do |num_str|
  num        = num_str.to_i
  db_pws     = db_passwords.first(num)
  conjur_pws = conjur_passwords.first(num)
  expect(db_pws).to match_array(conjur_pws)
end

Then(/^the first (\d+) conjur passwords are distinct$/) do |num_str|
  num        = num_str.to_i
  conjur_pws = conjur_passwords.first(num)
  expect(conjur_pws.size).to eq(num)
  expect(conjur_pws.uniq.size).to eq(num)
end

Then(/^the generated passwords have length (\d+)$/) do |len_str|
  length    = len_str.to_i
  conjur_pw = conjur_passwords.last
  expect(conjur_pw.length).to eq(length)
end

Given(/^I have the root policy:$/) do |policy|
  invoke do
    load_root_policy policy
  end
end

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


Then(/^I wait for (\d+) seconds?$/) do |num_seconds|
  puts "Sleeping #{num_seconds}...."
  sleep(num_seconds.to_i)
end
