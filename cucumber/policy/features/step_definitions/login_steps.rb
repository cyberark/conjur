# frozen_string_literal: true

# Since user is the default "role kind", the login is either going to be:
#   id       (in case of user)
#   host/id  (in case of host)
Given(/^I log in as ([\w_]+) "([^"]*)"$/) do |role_kind, id|
  @client = Client.for(role_kind, id)
end
