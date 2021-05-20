# frozen_string_literal: true

Given(/^I log in as ([\w_]+) "([^"]*)"$/) do |role_kind, id|
  login = if role_kind == "user"
    id
  else
    [ role_kind, id ].join('/')
  end
  login_as_role login
end
