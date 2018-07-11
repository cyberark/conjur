def gen_csr(id, signing_key, altnames)
  # create certificate subject
  common_name = id.gsub('/', '.')
  subject = OpenSSL::X509::Name.new [
    ['CN', common_name],
    # ['O', id],
    # ['C', id],
    # ['ST', id],
    # ['L', id]
  ]

  # create CSR
  csr = OpenSSL::X509::Request.new
  csr.version = 0
  csr.subject = subject
  csr.public_key = signing_key.public_key

  # prepare SAN extension
  extensions = [
      OpenSSL::X509::ExtensionFactory.new.create_extension('subjectAltName', altnames.join(','))
  ]

  # add SAN extension to the CSR
  attribute_values = OpenSSL::ASN1::Set [OpenSSL::ASN1::Sequence(extensions)]
  [
      OpenSSL::X509::Attribute.new('extReq', attribute_values),
      OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
  ].each do |attribute|
    csr.add_attribute attribute
  end

  # sign CSR with the signing key
  csr.sign signing_key, OpenSSL::Digest::SHA256.new

end

def login username, request_ip, authn_k8s_host, pkey
  csr = gen_csr(username, pkey, [
    "URI:spiffe://cluster.local/namespace/#{@pod.metadata.namespace}/pod/#{@pod.metadata.name}"
  ])

  resp = RestClient::Resource.new(authn_k8s_host)["inject_client_cert?request_ip=#{request_ip}"].post(csr.to_pem, content_type: 'text/plain')
  
  @cert = pod_certificate

  resp
end

Then(/^I( can)? login to pod matching "([^"]*)" to authn-k8s as "([^"]*)"$/) do |success, objectid, host_id|
  @request_ip ||= find_matching_pod(objectid)

  username = [ namespace, host_id ].join('/')
  begin
    @pkey = OpenSSL::PKey::RSA.new 1048
    login(username, @request_ip, authn_k8s_host, @pkey)
  rescue
    raise if success
    @error = $!
  end

  if @cert
    expect(@cert).to include("BEGIN CERTIFICATE")
  end
end

Then(/^I( can)? login to authn-k8s as "([^"]*)"$/) do |success, objectid|
  @request_ip ||= detect_request_ip(objectid)

  username = [ namespace, objectid ].join('/')
  begin
    @pkey = OpenSSL::PKey::RSA.new 1048
    login(username, @request_ip, authn_k8s_host, @pkey)
  rescue
    raise if success
    @error = $!
  end

  if @cert
    expect(@cert).to include("BEGIN CERTIFICATE")
  end
end

When(/^I launch many concurrent login requests$/) do
  objectid = "pod/inventory-pod"
  request_ip ||= detect_request_ip(objectid)
  @errors = errors = []

  username = [ namespace, "*", "*" ].join('/')

  @request_threads = (0...50).map do |i|
    sleep 0.05
    Thread.new do
      begin
        login(username, request_ip, authn_k8s_host, OpenSSL::PKey::RSA.new(1048))
      rescue
        errors << $!
      end
    end
  end
end

Then(/^at least one response status is (\d+)$/) do |arg1|
  @request_threads.map(&:join)

  expect(@errors.map{ |e| e.respond_to?(:http_code) && e.http_code }).to include(503)
end

When(/^the certificate subject name is "([^"]*)"$/) do |subject_name|
  certificate = OpenSSL::X509::Certificate.new(@cert)
  expect(certificate.subject.to_s).to eq(substitute(subject_name))
end

When(/^the certificate is valid for 3 days$/) do ||
  certificate = OpenSSL::X509::Certificate.new(@cert)
  expect(certificate.not_after - certificate.not_before).to eq(3 * 24 * 60 * 60)
end
