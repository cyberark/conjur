# frozen_string_literal: true

Given(/^I show the ([\w_]+) "([^"]*)"$/) do |kind, id|
  invoke do
    data = JSON.parse(get_roles(kind,id))
  end
end
