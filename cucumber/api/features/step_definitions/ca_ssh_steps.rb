Given(/^I have an ssh CA "([^"]*)"(?: with password "([^"]*)")?$/) do |ca_name, password|
  ssh_ca[ca_name] ||= generate_ssh_ca(ca_name, password)
end

Given(/^I add the "([^"]*)" ssh CA private key to the resource "([^"]*)"$/) do |ca_name, resource_id|
  Secret.create resource_id: resource_id, value: ssh_ca[ca_name].private_key
end

Given(/^I add the "([^"]*)" ssh CA public key to the resource "([^"]*)"$/) do |ca_name, resource_id|
  Secret.create resource_id: resource_id, value: ssh_ca[ca_name].public_key
end

When(/^I send a public key for "([^"]*)" to the "([^"]*)" CA with a ttl of "([^"]*)"$/) do |id_name, service_name, ttl|
  host = create_ssh_key(id_name)
  path = "/ca/cucumber/#{service_name}/certificates?kind=ssh"

  body = <<~BODY
    ttl=#{ttl}&public_key=#{CGI.escape(host.public_key)}&public_key_format=pem&principals=ubuntu
  BODY
  try_request false do
    post_json path, body
  end
end

Then(/^the resulting openssh certificate is valid according to the "([^"]*)" ssh CA$/) do |ca_name|
  @certificate_response_type = 'raw'

  signature_valid = response_ssh_certificate.signature_valid?
  signature_key_is_ca = response_ssh_certificate.signature_key.fingerprint == ssh_ca[ca_name].fingerprint

  expect(signature_valid && signature_key_is_ca).to eq(true)
end
