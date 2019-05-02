# frozen_string_literal: true

Given(/^I save the log data from bookmark$/) do
  save_num_log_lines()
end

And(/^The log filtered from bookmark contains messages:$/) do |message|
  expect(num_matches_since_savepoint(message)).to eq 1
end

And(/^The log filtered from bookmark "([^"]*)" contains "([^"]*)" messages:$/) do |occurrences, message|
  expect(num_matches_since_savepoint(message)).to eq occurrences.to_i
end