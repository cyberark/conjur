# frozen_string_literal: true

Given(/^I show the ([\w_]+) "([^"]*)"$/) do |kind, id|
  @client = Client.for("user", "admin")
  @result = @client.fetch_roles(kind: kind, id: id)
end
