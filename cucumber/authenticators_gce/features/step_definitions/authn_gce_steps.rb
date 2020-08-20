# Enable selective setting of GCE annotations
Given(/^I set (invalid )?"authn-gce\/(service-account-id|service-account-email|project-id|instance-name|invalid-key)" annotation to host "([^"]*)"$/) do |invalid, annotation_name, hostname|
  i_have_a_resource "host", hostname

  if invalid
    annotation_value = 'invalid'
  else
    case annotation_name
    when "service-account-id"
      annotation_value = gce_service_account_id
    when "service-account-email"
      annotation_value = gce_service_account_email
    when "project-id"
      annotation_value = gce_project_id
    when "instance-name"
      annotation_value = gce_instance_name
    when "invalid-key"
      annotation_value = 'invalid-annotation-key-value'
    else
      raise "Incorrect annotation name: '#{annotation_name}', expected: service-account-id|service-account-email|project-id|instance-name"
    end
  end

  set_annotation_to_resource("authn-gce/#{annotation_name}", annotation_value)
end

# Sets all GCE annotations
Given(/^I set all valid GCE annotations to host "([^"]*)"$/) do | hostname |
  i_have_a_resource "host", hostname

  set_annotation_to_resource("authn-gce/service-account-id", gce_service_account_id)
  set_annotation_to_resource("authn-gce/service-account-email", gce_service_account_email)
  set_annotation_to_resource("authn-gce/project-id", gce_project_id)
  set_annotation_to_resource("authn-gce/instance-name", gce_instance_name)
end

# Runs a curl command in a remote machine
Given(/^I obtain a GCE identity token in (full|standard) format with audience claim value: "([^"]*)"$/) do | format, audience |
  gce_identity_access_token(
    audience: audience,
    token_format: format
  )
end

# Authenticates with Conjur GCE authenticator
Given(/I authenticate with authn-gce using (valid|no|empty|invalid|self signed|no kid) token and (non-existing|existing) account/) do | token_state, account |
  account = account == 'non-existing' ? 'non-existing' : 'cucumber'

  token = case token_state
          when "no"
            nil
          when "empty"
            ""
          when "invalid"
            invalid_token
          when"self signed"
            self_signed_token
          when"no kid"
            no_kid_self_signed_token
          else
            @gce_identity_token
          end

  authenticate_gce_token(
    account:     account,
    gce_token:   token
  )
end
