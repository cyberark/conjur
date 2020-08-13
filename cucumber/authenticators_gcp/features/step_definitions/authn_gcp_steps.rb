
Given(/^I set GCP annotations to host "([^"]*)"$/) do |hostname|
    i_have_a_resource "host", hostname
    set_annotation_to_resource("authn-gcp/service-account-id", gcp_service_account_id)
end

Given(/^I obtain full format GCE identity token with audience claim "([^"]*)"$/) do | audience |
    gce_identity_access_token(audience: audience)
end

Given(/^I obtain a GCE identity token in "([^"]*)" format and with audience claim value: "([^"]*)"$/) do | audience |
    gce_identity_access_token(audience: audience)
end

Given(/I authenticate via GCP with token as host "([^"]*)"/) do |username|
    username = "host/#{username}"

end