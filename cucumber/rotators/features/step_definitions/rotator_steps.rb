# frozen_string_literal: true

Then(/^I create a db user "(.*?)" with password "(.*?)"$/) do |user, pw|
  # drop them first, in case we're re-running during dev
  run_sql_in_testdb("DROP DATABASE #{user};")
  run_sql_in_testdb("DROP USER #{user};")
  run_sql_in_testdb("CREATE USER #{user} WITH PASSWORD '#{pw}';")
  run_sql_in_testdb("CREATE DATABASE #{user};")
end

regex = /^I moniter "(.+)" and db user "(.+)" for (\d+) values in (\d+) seconds$/
Then(regex) do |var_name, db_user, vals_needed_str, timeout_str|
  @pg_pw_history = postgres_password_history(
    var_name: var_name,
    db_user: db_user,
    values_needed: vals_needed_str.to_i,
    timeout: timeout_str.to_i
  )
end

regex = /^I moniter AWS variables in policy "(.+)" for (\d+) values in (\d+) seconds$/
Then(regex) do |policy_id, vals_needed_str, timeout_str|
  @aws_credentials_history = aws_credentials_history(
    policy_id: policy_id,
    values_needed: vals_needed_str.to_i,
    timeout: timeout_str.to_i
  )
end

Then(/^the last two sets of AWS credentials both work$/) do
  @aws_credentials_history.last(2).all? do |creds|
    valid_aws_credentials?(creds)
  end
end

Then(/^the previous ones do not work$/) do
  @aws_credentials_history[0..-3].none? do |creds|
    valid_aws_credentials?(creds)
  end
end

Then(/^we find at least (\d+) distinct matching passwords$/) do |num_needed_str|
  # this is not really needed, as an error would have occured before getting
  # here if the values_needed had not been reached
  expect(@pg_pw_history.uniq.size).to be >= num_needed_str.to_i
end

Then(/^the generated passwords have length (\d+)$/) do |len_str|
  length = len_str.to_i
  conjur_pw = @pg_pw_history.last
  expect(conjur_pw.length).to eq(length)
end

Given(/^I have the root policy:$/) do |policy|
  @client = Client.for("user", "admin")
  @result = @client.load_policy(id: 'root', policy: policy)
end

Given(/^I reset my root policy$/) do
  @client = Client.for("user", "admin")
  @result = @client.load_policy(
    id: 'root',
    policy: <<~POLICY
      - !policy
         id: db-reports
         body:
    POLICY
  )
end

Given(/^I add the value "(.*)" to variable "(.+)"$/) do |val, id|
  @client.add_secret(id: id, value: val)
end

# There are two cases we have to handle during manual testing:
#
# 1. Running the test for the first time.  In this case, we must provide
#    the AWS credentials for our manual test account via the ENV.
# 2. Re-running the test during development.  In this case, we want to 
#    start with the value already in Conjur, so we do nothing
#
# NOTE: After finishing your testing, your creds will have been rotated,
#       and the credentials you started with will now be invalid.  Be sure
#       to record your last good credentials so that you won't be locked 
#       out of your test account.
#
regex = /^I ensure conjur has AWS test account credentials for policy "(.+)"$/
Then(regex) do |policy_id|
  region_var = variable("#{policy_id}/region")
  id_var     = variable("#{policy_id}/access_key_id")
  secret_var = variable("#{policy_id}/secret_access_key")
  creds_in_conjur = secret_var.version_count > 0 # only need to test 1 of them
  next if creds_in_conjur

  # If we're here, we're loading creds for the first time, and we assume
  # they are coming from the ENV

  region = ENV['AWS_DEFAULT_REGION']
  id     = ENV['AWS_ACCESS_KEY_ID']
  secret = ENV['AWS_SECRET_ACCESS_KEY']
  raise "'AWS_DEFAULT_REGION' is not defined in ENV" unless region
  raise "'AWS_ACCESS_KEY_ID' is not defined in ENV" unless id
  raise "'AWS_SECRET_ACCESS_KEY' is not defined in ENV" unless secret

  @client.add_secret("#{policy_id}/region", region)
  @client.add_secret("#{policy_id}/access_key_id", id)
  @client.add_secret("#{policy_id}/secret_access_key", secret)
end

# get-secret in metaproramming rotators stuff
# few other references in this file

Then(/^I add ENV\[(.+)\] to variable "(.+)"$/) do |env_var, conjur_varname|
  variable(conjur_varname)
  val = ENV[env_var]
  raise "'#{env_var}' is not defined in ENV" unless val

  @client.add_secret(conjur_varname, val)
end


Then(/^I wait for (\d+) seconds?$/) do |num_seconds|
  puts "Sleeping #{num_seconds}...."
  sleep(num_seconds.to_i)
end
