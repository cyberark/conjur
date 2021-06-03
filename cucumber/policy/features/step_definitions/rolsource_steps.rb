# frozen_string_literal: true

Given(/^I show the ([\w_]+) "([^"]*)"$/) do |kind, id|
  invoke do
    JSON.parse(get_roles(kind, id))
  end
end
