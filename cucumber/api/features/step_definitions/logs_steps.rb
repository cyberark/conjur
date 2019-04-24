# frozen_string_literal: true

Given(/^I save the amount of log lines into "([^"]*)"$/) do |bookmark|
  save_amount_of_log_lines(bookmark)
end


And(/^The log filtered from line number in "([^"]*)" should contains "([^"]*)" messages:$/) do |bookmark, occurrences, message|
  expect(occurences_in_log_filtered_from_bookmark(bookmark, message)).to eq occurrences.to_i
end