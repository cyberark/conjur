# frozen_string_literal: true

require 'socket'

Given(/^I request from authn-local:$/) do |claims|
  set_token_result authn_local_request(claims)
end

Then(/^I obtain an access token for "([^"]*)" in account "([^"]*)"$/) do |user_id, account|
  expect(token_payload['sub']).to eq(user_id)

  expect(token_protected['kid']).to eq(Slosilo["authn:#{account}"].fingerprint)
end

Then(/^the access token expires at (\d+)$/) do |exp|
  expect(token_payload['exp']).to eq(exp.to_i)
end

Then(/^the response is empty$/) do
  expect(@result).to be_blank
end
