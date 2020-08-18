Given(/^I set "authn-gce\/(service-account-id|service-account-email|project-id|instance-name)" annotation (with incorrect value )?to host "([^"]*)"$/) do |annotation_name, incorrect_value, hostname|
  i_have_a_resource "host", hostname

  case annotation_name
  when "service-account-id"
    annotation_value = gce_service_account_id
  when "service-account-email"
    annotation_value = gce_service_account_email
  when "project-id"
    annotation_value = gce_project_id
  when "instance-name"
    annotation_value = gce_instance_name
  else
    raise "Incorrect annotation name: '#{annotation_name}', expected: service-account-id|service-account-email|project-id|instance-name"
  end

  set_annotation_to_resource("#{annotation_name}", annotation_value)
end

Given(/^I obtain a GCE identity token in "([^"]*)" format with audience claim value: "([^"]*)"$/) do | audience, format |
  gce_identity_access_token(
    audience: audience,
    token_format: format
  )
end

Given(/I authenticate with authn-gce using Google identity token/) do
  authenticate_gce_token(
    account:     'cucumber',
    gce_token:   @gce_identity_token
  )
end
