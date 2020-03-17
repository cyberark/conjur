Given(/^I successfully set Azure variables$/) do
  set_azure_provider_uri_variable
end

Given(/^I successfully set Azure provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  set_azure_provider_uri_variable(provider_uri)
end

Given(/^I successfully set Azure provider-uri variable without trailing slash$/) do
  set_azure_provider_uri_variable(azure_provider_uri.chop)
end

Given(/I fetch an Azure access token from inside machine/) do
  retrieve_azure_access_token
end

Given(/I authenticate via Azure with token as (user|host) "([^"]*)"/) do |role_type, username|
  username = role_type == "user" ? username : "host/#{username}"

  authenticate_azure_token(
    service_id: 'prod',
    account: 'cucumber',
    username: username
  )
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
