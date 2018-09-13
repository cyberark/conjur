def login username, request_ip, authn_k8s_host, pkey
  csr = gen_csr(username, pkey, [
    "URI:spiffe://cluster.local/namespace/#{@pod.metadata.namespace}/pod/#{@pod.metadata.name}"
  ])

  response =
    RestClient::Resource.new(
      authn_k8s_host,
      ssl_ca_file: './nginx.crt'
    )["inject_client_cert?request_ip=#{request_ip}"].post(csr.to_pem, content_type: 'text/plain')
  
  p 'resp', resp
  @cert = pod_certificate
  p '@cert', @cert

  response
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
