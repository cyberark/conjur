Given(/^a root CA$/) do
  @root_ca = generate_root_ca
end

Given(/^an intermediate CA$/) do
  @intermediate_ca = generate_intermediate_ca(@root_ca)
end

When(/^I generate a host CSR$/) do
  @host ||= create_host
  @host_csr = @host.csr
end

When(/^I sign it using the intermediate CA$/) do
  @host_cert = @intermediate_ca.sign(@host_csr, 3600)
end

Then(/^the host certificate is valid according to the root CA$/) do
  store = OpenSSL::X509::Store.new
  store.add_cert @root_ca.cert
  store.add_cert @intermediate_ca.cert
  expect(store.verify(@host_cert)).to eq(true)
end
