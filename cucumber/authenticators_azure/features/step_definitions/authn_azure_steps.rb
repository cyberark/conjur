Given(/^I successfully set Azure variables with the correct values$/) do
  set_azure_provider_uri_variable
end

Given(/^I successfully set Azure provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  set_azure_provider_uri_variable(provider_uri)
end

Given(/^I successfully set Azure provider-uri variable without trailing slash$/) do
  set_azure_provider_uri_variable(azure_provider_uri.chop)
end

Given(/I fetch an Azure access token from inside machine/) do
  retrieve_system_assigned_azure_access_token
end

Given(/I fetch a user-assigned Azure access token from inside machine/) do
  retrieve_user_assigned_azure_access_token
end

Given(/I authenticate (?:(\d+) times? in (\d+) threads? )?via Azure with (no |empty |invalid )?token as (user|host) "([^"]*)"/) do |num_requests, num_threads, token_state, role_type, username|
  username = role_type == "user" ? username : "host/#{username}"

  token = case token_state
          when "no "
            nil
          when "empty "
            ""
          when "invalid "
            invalid_token
          else
            @azure_token
          end

  num_requests = 1 unless num_requests
  num_threads = 1 unless num_threads

  queue = (1..num_requests.to_i).inject(Queue.new, :push)
  results = []

  all_threads = Array.new(num_threads.to_i) do
    Thread.new do
      until queue.empty?
        queue.shift
        results.push(
          Benchmark.measure do
            authenticate_azure_token(
              service_id:  'prod',
              account:     'cucumber',
              username:    username,
              azure_token: token
            )
          end
        )
      end
    end
  end

  all_threads.each(&:join)
  @azure_perf_results = results.map(&:real)
end

Then(/^The "([^"]*)" Azure Authentication request response time should be less than "([^"]*)" seconds?$/) do |type, threshold|
  type = type.downcase.to_sym
  raise "Unexpected Type" unless %i(max avg).include?(type)
  results = @azure_perf_results
  actual_time = type == :avg ? results.sum.fdiv(results.size) : results.max
  expect(actual_time).to be < threshold.to_f
end

Given(/^I set Azure annotations to host "([^"]*)"$/) do |hostname|
  i_have_a_resource "host", hostname
  set_annotation_to_resource("authn-azure/subscription-id", azure_subscription_id)
  set_annotation_to_resource("authn-azure/resource-group", azure_resource_group)
end

Given(/^I set (subscription-id|resource-group|user-assigned-identity) annotation (with incorrect value )?to host "([^"]*)"$/) do |annotation_name, incorrect_value, hostname|
  i_have_a_resource "host", hostname

  case annotation_name
  when "subscription-id"
    annotation_correct_value = azure_subscription_id
  when "resource-group"
    annotation_correct_value = azure_resource_group
  when "user-assigned-identity"
    annotation_correct_value = user_assigned_identity
  else
    raise "incorrect annotation name #{annotation_name}"
  end

  annotation_value = incorrect_value ? "some-incorrect-value" : annotation_correct_value
  set_annotation_to_resource("authn-azure/#{annotation_name}", annotation_value)
end
