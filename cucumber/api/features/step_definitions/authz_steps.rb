# frozen_string_literal: true

Given(/^I create a new(?: "([^"]*)")? resource(?: called "([^"]*)")?$/) do |kind, identifier|
  kind ||= "test-resource"
  identifier ||= random_hex
  identifier = denormalize identifier
  resource_id = "cucumber:#{kind}:#{identifier}"

  @resources ||= {}
  
  @current_resource =
    Resource.create(resource_id: resource_id,
                    owner: @current_user || admin_user)

  @resources[resource_id] = @current_resource
end

Given(/^I add an annotation value of(?: "([^"]*)")? to the resource$/) do |annotation_value|
  @current_resource.annotations <<
    Annotation.create(resource: @current_resource,
                      name: "key",
                      value: annotation_value)
end

Given(/^I create a new searchable resource(?: called "([^"]*)")?$/) do |identifier|
  kind = "test-resource"
  identifier ||= random_hex
  identifier = denormalize identifier

  @searchable_resources ||= []
  @searchable_resources <<
    Resource.create(resource_id: "cucumber:#{kind}:#{identifier}",
                    owner: @current_user || admin_user)
end

Given(/^I create a new resource in a foreign account$/) do
  account = random_hex
  kind = "test-resource"
  identifier = random_hex
  
  @current_resource =
    Resource.create(resource_id: "#{account}:#{kind}:#{identifier}",
                    owner: foreign_admin_user(account))
end

Given(/^I create (\d+) new resources$/) do |count|
  kind = "test-resource"

  @resources ||= {}
  
  count.to_i.times do
    identifier ||= random_hex
    identifier = denormalize identifier
    resource_id = "cucumber:#{kind}:#{identifier}"
    
    @current_resource =
      Resource.create(resource_id: resource_id,
                      owner: @current_user || admin_user)
    
    @resources[resource_id] = @current_resource
  end
end

Given(/^I permit role "([^"]*)" to "([^"]*)" resource "([^"]*)"$/) do |grantee, privilege, target|
  grantee = Role.with_pk!(grantee)
  target = Resource.with_pk!(target)
  target.permit privilege, grantee
end

Given(/^I permit user "([^"]*)" to "([^"]*)" user "([^"]*)"$/) do |grantee, privilege, target|
  grantee = lookup_user(grantee)
  target = lookup_user(target)
  target.resource.permit privilege, grantee
end

Given(/^I set annotation "([^"]*)" to "([^"]*)"$/) do |name, value|
  @current_resource.add_annotation name: name, value: value
end

Given(/^I create (\d+) secret values?$/) do |n|
  n.to_i.times do |i|
    Secret.create resource_id: @current_resource.id, value: i.to_s
  end
end

Given(/^I create a binary secret value?$/) do
  @value = Random.new.bytes(16)
  Secret.create resource_id: @current_resource.id, value: @value
end

Given(/^I add the secret value(?: "([^"]*)")? to the resource(?: "([^"]*)")?$/) do |value, resource_id|
  Secret.create resource_id: resource_id, value: value
end

Given(/^I permit user "([^"]*)" to "([^"]*)" it$/) do |grantee, privilege|
  grantee = lookup_user(grantee)
  target = @current_resource
  target.permit privilege, grantee
end

Given(/^I grant my role to user "([^"]*)"$/) do |login|
  grantee = lookup_user(login)
  @current_user.grant_to grantee
end

Given(/^I grant user "([^"]*)" to user "([^"]*)"$/) do |grantor, grantee|
  grantor = lookup_user(grantor)
  grantee = lookup_user(grantee)
  grantor.grant_to grantee
end
