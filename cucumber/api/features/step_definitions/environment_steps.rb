# frozen_string_literal: true

Given(/^I set environment variable "([^"]*)" to "([^"]*)"$/) do |variable_name, variable_value|
  ENV[variable_name] = variable_value
end
