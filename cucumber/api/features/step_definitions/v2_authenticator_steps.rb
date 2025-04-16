# frozen_string_literal: true

Then(/^the authenticators list should include "([^"]*)"$/) do |resource_id|
  expect(@result['authenticators'].map{|r| r['name']}).to include(resource_id)
end
