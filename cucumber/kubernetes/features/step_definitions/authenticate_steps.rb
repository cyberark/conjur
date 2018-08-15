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
    expect(token.username).to eq(username)
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
    expect(token.username).to eq(username)
  end
end

def conjur_resource_id(namespace, resource_id)
  "host/conjur/authn-k8s/minikube/apps/#{namespace}/#{resource_id}"
end
