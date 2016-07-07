Given(/^a resource$/) do
  @current_resource = Resource.create(resource_id: "cucumber:test-resource:#{SecureRandom.uuid}", owner: @current_user)
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

When(/^I check if user "([^"]*)" can "([^"]*)" it$/) do |login, privilege|
  role = lookup_user(login)
  @result = @current_user.api.role(role.id).permitted? @current_resource.id, privilege
end

When(/^I check if I can "([^"]*)" it$/) do |privilege|
  @result = @current_user.api.resource(@current_resource.id).permitted? privilege
end

When(/^I list the roles who can "([^"]*)" it$/) do |privilege|
  @result = @current_user.api.resource(@current_resource.id).permitted_roles(privilege).sort
end

When(/^I list all resources(?: whose kind is "([^"]*)")?$/) do |kind|
  options = {}
  options[:kind] = kind if kind
  @result = @current_user.api.resources(options)
end
