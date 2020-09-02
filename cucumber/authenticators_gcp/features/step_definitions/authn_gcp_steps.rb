# Enable selective setting of GCP annotations
Given(/^I set (invalid )?"authn-gcp\/(service-account-id|service-account-email|project-id|instance-name|invalid-key)" annotation to host "([^"]*)"$/) do |invalid, annotation_name, hostname|
  i_have_a_resource "host", hostname

  if invalid
    annotation_value = 'invalid'
  else
    case annotation_name
    when "service-account-id"
      annotation_value = gcp_service_account_id
    when "service-account-email"
      annotation_value = gcp_service_account_email
    when "project-id"
      annotation_value = gcp_project_id
    when "instance-name"
      annotation_value = gcp_instance_name
    when "invalid-key"
      annotation_value = 'invalid-annotation-key-value'
    else
      raise "Incorrect annotation name: '#{annotation_name}', expected: service-account-id|service-account-email|project-id|instance-name"
    end
  end

  set_annotation_to_resource("authn-gcp/#{annotation_name}", annotation_value)
end

# Sets all GCP annotations
Given(/^I set all valid GCP annotations to (user|host) "([^"]*)"$/) do |role_type, hostname|
  i_have_a_resource role_type, hostname

  set_annotation_to_resource("authn-gcp/service-account-id", gcp_service_account_id)
  set_annotation_to_resource("authn-gcp/service-account-email", gcp_service_account_email)
  set_annotation_to_resource("authn-gcp/project-id", gcp_project_id)
  set_annotation_to_resource("authn-gcp/instance-name", gcp_instance_name)
end

# Runs a curl command in a remote machine
Given(/^I obtain an? (valid|standard_format|user_audience|invalid_audience|non_existing_host|non_rooted_host|non_existing_account) GCP identity token$/) do |token_type|
  gcp_identity_access_token(
    token_type.to_sym
  )
end

# Authenticates with Conjur GCP authenticator
Given(/I authenticate (?:(\d+) times? in (\d+) threads? )?with authn-gcp using (no|empty|self signed|no kid|obtained|valid) token and (non-existing|existing) account/) do |num_requests, num_threads, token_state, account|
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
            @gcp_identity_token
          end

  num_requests ||= 1
  num_threads  ||= 1

  authenticate_with_performance(
    num_requests,
    num_threads,
    authentication_func:        :authenticate_gcp_token,
    authentication_func_params: {
      account:   account,
      gcp_token: token
    }
  )
end
