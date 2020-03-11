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
