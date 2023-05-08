# frozen_string_literal: true

# NOTE: I saw no reason to make this dynamically accept parameters --
#       the step is by nature coupled to the expiration feature, so
#       hardcoding these values should actually be preferred.
#
Then(/^I wait until the initial password has rotated away$/) do
  @history_before_expiration = pg_history_after_rotation(
    var_name: 'db-reports/password',
    db_user: 'test',
    orig_pw: 'secret'
  )
end

Then(/^the password will change from "(.+)"$/) do |saved_result_key|
  old_value = @saved_results[saved_result_key]

  # We don't care about the value returned in this case.  As long as the method
  # returns without error, we know the password changed
  #
  pg_history_after_rotation(
    var_name: 'db-reports/password',
    db_user: 'test',
    orig_pw: old_value
  )
end

## TODO: create a step to remove the hardcoded testdb url test
#And(/^And I add the value "(.*)" to variable "(.*)"$/) do |url, _|
  #url"#{ENV['TEST_ENV_NUMBER']}"
#end