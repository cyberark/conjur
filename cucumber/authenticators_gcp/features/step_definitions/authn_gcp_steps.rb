# Enable selective setting of GCP annotations
Given(%r{^I set (invalid )?"authn-gcp/(service-account-id|service-account-email|project-id|instance-name|invalid-key)" GCE annotation to host "([^"]*)"$}) do |invalid, annotation_name, hostname|
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

  set_annotation_to_resource("authn-gcp/#{annotation_name}", annotation_value)
end

Given(%r{^I set "authn-gcp/(service-account-id|service-account-email|project-id|instance-name)" GCF annotation to host "([^"]*)"$}) do |annotation_name, hostname|
  i_have_a_resource "host", hostname

  case annotation_name
  when "service-account-id"
    annotation_value = gcf_service_account_id
  when "service-account-email"
    annotation_value = gcf_service_account_email
  when "project-id"
    annotation_value = "_"
  when "instance-name"
    annotation_value = "_"
  else
    raise "Incorrect annotation name: '#{annotation_name}', expected: service-account-id|service-account-email|project-id|instance-name"
  end

  set_annotation_to_resource("authn-gcp/#{annotation_name}", annotation_value)
end

Given(%r{^I set "authn-gcp/(service-account-id|service-account-email)" annotation with value: "([^"]*)" to host "([^"]*)"$}) do |annotation_name, annotation_value, hostname|
  i_have_a_resource "host", hostname
  set_annotation_to_resource("authn-gcp/#{annotation_name}", annotation_value)
end

Given(/^I set all valid GCE annotations to (user|host) "([^"]*)"$/) do |role_type, hostname|
  i_have_a_resource role_type, hostname

  set_annotation_to_resource("authn-gcp/service-account-id", gce_service_account_id)
  set_annotation_to_resource("authn-gcp/service-account-email", gce_service_account_email)
  set_annotation_to_resource("authn-gcp/project-id", gce_project_id)
  set_annotation_to_resource("authn-gcp/instance-name", gce_instance_name)
end

Given(/^I set all valid GCF annotations to (user|host) "([^"]*)"$/) do |role_type, hostname|
  i_have_a_resource role_type, hostname

  set_annotation_to_resource("authn-gcp/service-account-id", gcf_service_account_id)
  set_annotation_to_resource("authn-gcp/service-account-email", gcf_service_account_email)
end

Given(%r{^I set "authn-gcp/(service-account-id|service-account-email)" GCF annotations to (user|host) "([^"]*)"$}) do |annotation_type, role_type, hostname|
  i_have_a_resource role_type, hostname

  if annotation_type == 'id'
    set_annotation_to_resource("authn-gcp/service-account-id", gcf_service_account_id)
  else
    set_annotation_to_resource("authn-gcp/service-account-email", gcf_service_account_email)
  end
end

Given(/^I obtain a valid GCF identity token$/) do
  gcf_identity_access_token(
    "valid".to_sym
  )
end

Given(/I authenticate with authn-gcp using a valid GCF identity token/) do
  authenticate_gcp_token(
    account: AuthnGcpHelper::ACCOUNT,
    gcp_token: @gcf_identity_token
  )
end

Given(/I authenticate with authn-gcp using no token( and user id "([^"]*)" in the request)?$/) do |user_id|
  authenticate_gcp_token(
    account: AuthnGcpHelper::ACCOUNT,
    gcp_token: nil,
    user_id: user_id
  )
end

Given(/^I obtain an? (valid|standard_format|user_audience|invalid_audience|non_existing_host|non_rooted_host|non_existing_account) GCE identity token$/) do |token_type|
  gce_identity_access_token(
    token_type.to_sym
  )
end

# Authenticates with Conjur GCP authenticator
Given(/I authenticate (?:(\d+) times? in (\d+) threads? )?with authn-gcp using (no|empty|self signed|no kid|obtained GCE|valid GCE) token and (non-existing|existing) account/) do |num_requests, num_threads, token_state, account|
  account = account == 'non-existing' ? 'non-existing' : AuthnGcpHelper::ACCOUNT

  token = case token_state
          when "no"
            nil
          when "empty"
            ""
          when "self signed"
            self_signed_token
          when "no kid"
            no_kid_self_signed_token
          else
            @gce_identity_token
  end

  num_requests ||= 1
  num_threads  ||= 1

  authenticate_with_performance(
    num_requests,
    num_threads,
    authentication_func: :authenticate_gcp_token,
    authentication_func_params: {
      account: account,
      gcp_token: token
    }
  )
  # If the called failed retry to send it
  if http_status != 200
    authenticate_with_performance(
      num_requests,
      num_threads,
      authentication_func: :authenticate_gcp_token,
      authentication_func_params: {
        account: account,
        gcp_token: token
      }
    )
  end
end
