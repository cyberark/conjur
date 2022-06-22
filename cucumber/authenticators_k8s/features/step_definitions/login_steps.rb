def login username, request_ip, authn_k8s_host, pkey, headers = {}
  csr = gen_csr(username, pkey, [
    "URI:spiffe://cluster.local/namespace/#{@pod.metadata.namespace}/pod/#{@pod.metadata.name}"
  ])

  headers[:content_type] = 'text/plain'

  clear_pod_certificate
  response =
    RestClient::Resource.new(
      authn_k8s_host,
      ssl_ca_file: './nginx.crt',
      headers: headers
    )["inject_client_cert?request_ip=#{request_ip}"].post(csr.to_pem)

  @cert = pod_certificate

  if @cert.to_s.empty?
    puts("WARN: Certificate is empty!")
    warn("WARN: Certificate is empty!")
  end

  puts "GOT CERT:", @cert.to_s
  puts "FOR KEY:", pkey.to_s

  response
end

def login_with_hard_coded_prefix request_ip, id, success
  username = [ namespace, id ].join('/')
  login_with_username(request_ip, username, success)
end

def login_with_custom_prefix request_ip, host_id_suffix, host_id_prefix, success
  headers = { 'Host-Id-Prefix' => host_id_prefix.tr('/', '.') }
  username = substitute!(host_id_suffix)

  login_with_username(request_ip, username, success, headers)
end

def login_with_username request_ip, username, success, headers = {}
  begin
    @pkey = OpenSSL::PKey::RSA.new(2048)
    response = login(username, request_ip, authn_k8s_host, @pkey, headers)
    expect(response.code).to be(202)
  rescue
    raise if success

    @error = $!
  end

  expect(@cert).to include("BEGIN CERTIFICATE") unless @cert.to_s.empty?
end

Then(/^I( can)? login to pod matching "([^"]*)" to authn-k8s as "([^"]*)"(?: with prefix "([^"]*)")?$/) do |success, objectid, host_id_suffix, host_id_prefix|
  @request_ip ||= find_matching_pod(objectid)

  if host_id_prefix
    login_with_custom_prefix(@request_ip, host_id_suffix, host_id_prefix, success)
  else
    login_with_hard_coded_prefix(@request_ip, host_id_suffix, success)
  end
end

Then(/^I( can)? login to authn-k8s as "([^"]*)"(?: with prefix "([^"]*)")?$/) do |success, host_id_suffix, host_id_prefix|
  if host_id_prefix
    # we take only the object type and id to detect the request_ip
    objectid = host_id_suffix.split('/').last(2).join('/')
    @request_ip ||= detect_request_ip(objectid)
    login_with_custom_prefix(@request_ip, host_id_suffix, host_id_prefix, success)
  else
    @request_ip ||= detect_request_ip(host_id_suffix)
    login_with_hard_coded_prefix(@request_ip, host_id_suffix, success)
  end
end

When(/^I launch many concurrent login requests$/) do
  objectid = "pod/inventory-pod"
  request_ip ||= detect_request_ip(objectid)
  @errors = errors = []

  username = [ namespace, "*", "*" ].join('/')

  @request_threads = (0...50).map do |i|
    sleep(0.05)
    Thread.new do
      begin
        login(username, request_ip, authn_k8s_host, OpenSSL::PKey::RSA.new(2048))
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
  expect(certificate.subject.to_s).to eq(substitute!(subject_name))
end

When(/^the certificate is valid for 3 days$/) do ||
  certificate = OpenSSL::X509::Certificate.new(@cert)
  expect(certificate.not_after - certificate.not_before).to eq(3 * 24 * 60 * 60)
end

Then(/^the cert injection logs exist in the client container$/) do
  expect(@cert_injection_logs).to include("Directory nonexistent")
end
