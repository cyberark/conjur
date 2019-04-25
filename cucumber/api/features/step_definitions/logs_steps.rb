# frozen_string_literal: true

Given(/^I save the log data from bookmark "([^"]*)"$/) do |bookmark|
  save_log_data_from_bookmark(bookmark)
end


And(/^The log filtered from bookmark "([^"]*)" contains "([^"]*)" messages:$/) do |bookmark, occurrences, message|
  expect(occurences_in_log_filtered_from_bookmark(bookmark, message)).to eq occurrences.to_i
end