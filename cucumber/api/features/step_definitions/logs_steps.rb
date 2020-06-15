# frozen_string_literal: true

# we actually don't do anything with the `_is_audit` param as audit messages
# are written to the Rails log. We have this param for readability of the
# cucumber steps

Given(/^I save my place in the (audit )?log file$/) do |_is_audit|
  save_num_log_lines
end

And(/^The following appears in the (audit )?log after my savepoint:$/) do |_is_audit, message|
  expect(num_matches_since_savepoint(message)).to be >= 1
end

And(/Alice's API key does not appear in the log/) do
  expect(
    num_matches_since_savepoint(api_key_for_role_id("cucumber:user:alice"))
  ).to be(0)
end

And(/^The following appears ([^"]*) times? in the (audit )?log after my savepoint:$/) do |occurrences, _is_audit, message|
  expect(num_matches_since_savepoint(message)).to eq occurrences.to_i
end
