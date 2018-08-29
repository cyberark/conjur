Given(/^I have an intermediate CA "([^"]*)"(?: with password "([^"]*)")?$/) do |ca_name, password|
  @root_ca ||= generate_root_ca
  intermediate_ca[ca_name] ||= generate_intermediate_ca(@root_ca, password)
end

Given(/^I add the "([^"]*)" intermediate CA private key to the resource "([^"]*)"$/) do |ca_name, resource_id|
  Secret.create resource_id: resource_id, value: intermediate_ca[ca_name].key_pem
end

Given(/^I add the "([^"]*)" intermediate CA cert chain to the resource "([^"]*)"$/) do |ca_name, resource_id|
  chain = [
    intermediate_ca[ca_name].cert.to_pem,
    @root_ca.cert.to_pem
  ].join("\n")
  Secret.create resource_id: resource_id, value: chain
end

When(/^I send a CSR for "([^"]*)" to the "([^"]*)" CA with a ttl of "([^"]*)" and CN of "([^"]*)"$/) do |_host_name, service_name, ttl, common_name|
  host = create_host(common_name)
  path = "/ca/cucumber/#{service_name}/sign"

  # TODO: It would be nice if this also worked with multipart/form-data

  body = <<~BODY
    ttl=#{ttl}&csr=#{CGI.escape(host.csr.to_pem)}
  BODY
  try_request false do
    post_json path, body
  end
end

Then(/^the resulting (pem|json) certificate is valid according to the "([^"]*)" intermediate CA$/) do |type, ca_name|
  cert_body = (type == 'pem' ? @result : @result['certificate'])
  cert = OpenSSL::X509::Certificate.new cert_body

  store = OpenSSL::X509::Store.new
  store.add_cert @root_ca.cert
  store.add_cert intermediate_ca[ca_name].cert

  expect(store.verify(cert)).to eq(true)
end
