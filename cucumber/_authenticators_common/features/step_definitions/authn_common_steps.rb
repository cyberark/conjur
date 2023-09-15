Then(/^(user|host) "(\S+)" has been authorized by Conjur$/) do |role_type, username|
  username = role_type == "user" ? username : "host/#{username}"
  expect(retrieved_access_token.username).to eq(username)
end

Then(/^login response token is valid$/) do
  expect(token_for_keys(%w[user_name expiration_time id_token_encrypted], @response_body)).to be
end

Then(/it is a bad request/) do
  expect(bad_request?).to be(true), "http status is #{http_status}"
end

Then(/it is unauthorized/) do
  expect(unauthorized?).to be(true), "http status is #{http_status}"
end

Then(/it is forbidden/) do
  expect(forbidden?).to be(true), "http status is #{http_status}"
end

Then(/it is not found/) do
  expect(not_found?).to be(true), "http status is #{http_status}"
end

Then(/it is gateway timeout/) do
  expect(gateway_timeout?).to be(true), "http status is #{http_status} & rest client error is #{rest_client_error.class}"
end

Then(/it is bad gateway/) do
  expect(bad_gateway?).to be(true), "http status is #{http_status}"
end

Then(/authenticator "([^"]*)" is enabled/) do |resource_id|
  config = AuthenticatorConfig.where(resource_id: resource_id).first
  expect(config.enabled).to eq(true)
end

Then(/authenticator "([^"]*)" is disabled/) do |resource_id|
  config = AuthenticatorConfig.where(resource_id: resource_id).first
  expect(config&.enabled).to be_falsey
end

Then(/The (avg|max) authentication request responds in less than (\d+\.?(\d+)?) seconds?/) do |type, threshold|
  validate_authentication_performance(type, threshold)
end

Given(/I set the following conjur variables:/) do |table|
  client = Client.for("user", "admin")
  table.hashes.each do |variable_hash|
    # If default value is present, use it.
    value = variable_hash['default_value']
    unless value.present?
      # Otherwise, fall back to Scenario Context variable.
      value = @scenario_context.get(variable_hash['context_variable'].to_sym)

      if value.blank?
        raise "Context Variable '#{variable_hash['context_variable']}' has not been set."
      end
    end

    client.add_secret(id: variable_hash['variable_id'], value: value)
  end
end

Given(/the following environment variables are available:/) do |table|
  table.hashes.each do |variable_hash|
    # If environment variable is present, use that, otherwise use default.
    value = ENV.fetch(variable_hash['environment_variable'], variable_hash['default_value'])
    if value.blank?
      raise "Environment variable: '#{variable_hash['environment_variable']}' must be set"
    end

    @scenario_context.add(variable_hash['context_variable'].to_sym, value)
  end
end

Given(/^I set environment variable "([^"]*)" to "([^"]*)"$/) do |variable_name, variable_value|
  ENV[variable_name] = variable_value
end
