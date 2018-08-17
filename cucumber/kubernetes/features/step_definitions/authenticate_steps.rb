def conjur_resource_id(namespace, resource_id)
  "host/conjur/authn-k8s/minikube/apps/#{namespace}/#{resource_id}"
end

def gen_cert(host_id)
  id = 'conjur/authn-k8s/minikube'
  conjur_account = ENV['CONJUR_ACCOUNT']
  subject = "/CN=#{id.tr('/', '.')}/OU=Conjur Kubernetes CA/O=#{conjur_account}"
  ca_cert, ca_key = Authentication::AuthnK8s::CA.generate(subject)
  ca = Authentication::AuthnK8s::CA.new(ca_cert, ca_key)

  metadata = @pod.metadata
  spiffe_id = "URI:spiffe://cluster.local/namespace/#{metadata.namespace}/pod/#{metadata.name}"

  username = [namespace, host_id].join('/')
  @pkey = OpenSSL::PKey::RSA.new 1048
  csr = gen_csr(username, @pkey, [spiffe_id])
  
  ca.issue(csr, [spiffe_id])
end

Given(/^I use the IP address of(?: a pod in)? "([^"]*)"$/) do |objectid|
  @request_ip = find_matching_pod(objectid)
end

Then(/^I( can)? authenticate with authn-k8s as "([^"]*)"( without cert and key)?$/) do |success, objectid, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  conjur_id = conjur_resource_id(namespace, objectid)

  cert = nocertkey ? nil : OpenSSL::X509::Certificate.new(@cert)
  key = nocertkey ? nil : @pkey

  begin
    response = RestClient::Resource.new(
      authn_k8s_host,
      ssl_ca_file: './nginx.crt',
      ssl_client_cert: cert,
      ssl_client_key: key,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER
    )["#{ENV['CONJUR_ACCOUNT']}/#{CGI.escape conjur_id}/authenticate?request_ip=#{@request_ip}"].post('')
  rescue
    raise if success
    @error = $!
  end

  unless response.nil?
    token = ConjurToken.new(response.body)
    expect(token.username).to eq(conjur_id)
  end
end

Then(/^I( can)? authenticate pod matching "([^"]*)" with authn-k8s as "([^"]*)"( without cert and key)?$/) do |success, objectid, hostid, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  conjur_id = conjur_resource_id(namespace, hostid)
  
  cert = nocertkey ? nil : OpenSSL::X509::Certificate.new(@cert)
  key = nocertkey ? nil : @pkey
  
  begin
    response = RestClient::Resource.new(
      authn_k8s_host,
      ssl_ca_file: './nginx.crt',
      ssl_client_cert: cert,
      ssl_client_key: key,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER
    )["#{ENV['CONJUR_ACCOUNT']}/#{CGI.escape conjur_id}/authenticate?request_ip=#{@request_ip}"].post('')
  rescue
    raise if success
    @error = $!
  end

  unless response.nil?
    token = ConjurToken.new(response.body)
    expect(token.username).to eq(conjur_id)
  end
end

Then(/^I cannot authenticate with pod matching "([^"]*)" as "([^"]*)" using a cert signed by a different CA?$/) do |object_id, host_id|
  @request_ip ||= detect_request_ip(object_id)
  
  cert = gen_cert(host_id)

  conjur_id = conjur_resource_id(namespace, host_id)

  begin
    RestClient::Resource.new(
      authn_k8s_host,
      ssl_ca_file: './nginx.crt',
      ssl_client_cert: cert,
      ssl_client_key: @pkey,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER
    )["#{ENV['CONJUR_ACCOUNT']}/#{CGI.escape conjur_id}/authenticate?request_ip=#{@request_ip}"].post('')
  rescue
    @error = $!
  end

  expect(@error.http_code).to eq(401)
end
