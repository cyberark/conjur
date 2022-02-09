# frozen_string_literal: true

When(/^I persist an "([^"]*)" authenticator with service id "([^"]*)"$/) do |authenticator, service_id|
  path = format("/%s/%s/cucumber", authenticator, service_id)

  try_request true do
    post_json path, ""
  end
end

When(/^I persist an "([^"]*)" authenticator with service id "([^"]*)" and JSON:$/) do |authenticator, service_id, value|
  path = format("/%s/%s/cucumber", authenticator, service_id)

  try_request true do
    post_json path, value
  end
end
