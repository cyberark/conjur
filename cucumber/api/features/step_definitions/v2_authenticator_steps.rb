# frozen_string_literal: true

Then(/^the authenticators list should (not )?include "([^"]*)"$/) do |invert, resource_id|
  sub = expect(@result['authenticators'].map{|r| r['name']})

  if invert.nil?
    sub.to include(resource_id)
  else
    sub.not_to include(resource_id)
  end
end
