# frozen_string_literal: true

# we actually don't do anything with the `_` param as audit messages
# are written to the Rails log. We have this param for readability of the
# cucumber steps

Given(/^I save my place in the (audit )?log file$/) do |_|
  save_num_log_lines
end

# NOTE: The source code order of this step def and the one above matters.
And(/^The following matches the (audit )?log after my savepoint:$/) do |_, message|
  expect(num_matches_since_savepoint(message)).to be >= 1
end

# NOTE: The source code order of this step def and the one above matters.
And(/^The following appears in the (audit )?log after my savepoint:$/) do |_, message|
  expect(num_matches_since_savepoint(Regexp.escape(message))).to be >= 1
end

# NOTE: The source code order of this step def and the one above matters.
And(/^The following appears ([^"]*) times? in the (audit )?log after my savepoint:$/) \
  do |occurrences, _, message|
  expect(num_matches_since_savepoint(message)).to eq occurrences.to_i
end

And(/Alice's API key does not appear in the log/) do
  expect(
    num_matches_since_savepoint(api_key_for_role_id("cucumber:user:alice"))
  ).to be(0)
end
