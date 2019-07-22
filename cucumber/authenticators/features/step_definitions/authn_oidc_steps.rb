Given(/^I get authorization code for username "([^"]*)" and password "([^"]*)"$/) do |username, password|
  oidc_authorization_code(username: username, password: password)
end

Given(/I fetch an ID Token/) do
  fetch_oidc_id_token
end

Given(/^I successfully set OIDC variables$/) do
  set_oidc_variables
end

Given(/^I successfully set provider-uri variable$/) do
  set_provider_uri_variable
end

Given(/^I successfully set provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  set_provider_uri_variable(provider_uri)
end

Given(/^I successfully set id-token-user-property variable$/) do
  set_id_token_user_property_variable
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber')
end

When(/^I authenticate via OIDC with id token and account "([^"]*)"$/) do |account|
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: account)
end

When(/^I authenticate via OIDC with no id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: nil)
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(service_id: 'keycloak', account: 'cucumber', id_token: "")
end

When(/^I authenticate "([^"]*)" times in "([^"]*)" threads via OIDC with id token$/) do |num_requests, num_threads|
  measure_oidc_performance(num_requests: num_requests.to_i, num_threads: num_threads.to_i, service_id: 'keycloak', account: 'cucumber')
end

When(/^I authenticate "([^"]*)" times in "([^"]*)" threads via OIDC with invalid id token$/) do |num_requests, num_threads|
  invalid_id_token = "eyJhbGciOiJSUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJmV09wT3JvTjk0WXgxeEh2THpTVHJ0V01WbGxtLV84eGE3OUVYWTVfbTlZIn0.eyJqdGkiOiJiNjNjYTk1ZC1iZjBlLTQyY2EtODY5Yy00OTg0ZGRiNzUxOWMiLCJleHAiOjE1NTc5OTUxMjMsIm5iZiI6MCwiaWF0IjoxNTU3OTk1MDYzLCJpc3MiOiJodHRwOi8vMC4wLjAuMDo3Nzc3L2F1dGgvcmVhbG1zL21hc3RlciIsImF1ZCI6ImNvbmp1ckNsaWVudCIsInN1YiI6ImJmMTI0MTFlLWQ5YTktNGRhMy05ODJmLTgxMzY5ZjFiMDljZCIsInR5cCI6IklEIiwiYXpwIjoiY29uanVyQ2xpZW50IiwiYXV0aF90aW1lIjoxNTU3OTk1MDUwLCJzZXNzaW9uX3N0YXRlIjoiYmE2YjkzODEtZDBkYi00MjE5LTlhYjEtODE3MWRkMjViOWU5IiwiYWNyIjoiMSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwicHJlZmVycmVkX3VzZXJuYW1lIjoiYWxpY2UiLCJlbWFpbCI6ImFsaWNlQGNvbmp1ci5uZXQifQ.Xo52kQ44DP9VFaLbnJYbw2hkK9s2eWBqxeqKd6uwua91mWl0McVUl3wWaz3exZ4t_N0mmXFfs5gSFIo8hsdhOpp263bRV16HSOFruhf0Kq-vE6_Ix5NbiFLaCE8Y2LhrWLXL1tJO1wEjM59uZak7203Wm2tA2p_6O8Dc0_i8QYVm_x__icSDOGy8V_Kic9B5PeVkZNV74H1fuuALaRMG-G-lfyY7HDcSmJ7kPF7sM_7_IeJSNbxJm1aznWYA-XoAY1eb9sEPfQ7BrknGAo5Z2z3MKpi69fQeA00B7Jpn5fInPhhryT0hIk49vd4hWdN14Cwr1L_DCAc1sfkXJtY_xg"
  measure_oidc_performance(num_requests: num_requests.to_i, num_threads: num_threads.to_i, service_id: 'keycloak', account: 'cucumber', id_token: invalid_id_token)
end

Then(/^The "([^"]*)" response time should be less than "([^"]*)" seconds$/) do |type, threshold|
  ensure_performance_result(type, threshold.to_f)
end
