Given(/^I have an intermediate CA$/) do
  @root_ca ||= generate_root_ca
  @intermediate_ca = generate_intermediate_ca(@root_ca)
end

Given(/^I add the intermediate CA private key to the resource "([^"]*)"$/) do |resource_id|
  Secret.create resource_id: resource_id, value: @intermediate_ca.key.to_pem
end

Given(/^I add the intermediate CA cert chain to the resource "([^"]*)"$/) do |resource_id|
  chain = [
    @intermediate_ca.cert.to_pem,
    @root_ca.cert.to_pem
  ].join("\n")
  Secret.create resource_id: resource_id, value: chain
end

When(/^I send a CSR for "([^"]*)" to the "([^"]*)" CA with a ttl of "([^"]*)" and CN of "([^"]*)"$/) do |host_name, service_name, ttl, common_name|
  host = create_host(common_name)
  path = "/ca/cucumber/#{service_name}/hosts/#{host_name}"

  # TODO: It would be nice if this also worked with multipart/form-data

  body = <<~BODY
  ttl=#{ttl}&csr=#{CGI.escape(host.csr.to_pem)}
  BODY
  try_request false do
    post_json path, body
  end
end

Then(/^the resulting certificate is valid according to the intermediate CA$/) do
  cert = OpenSSL::X509::Certificate.new @result["certificate"]

  store = OpenSSL::X509::Store.new
  store.add_cert @root_ca.cert
  store.add_cert @intermediate_ca.cert

  expect(store.verify(cert)).to eq(true)
end
