Given(/^I use the IP address of(?: a pod in)? "([^"]*)"$/) do |objectid|
  @request_ip = find_matching_pod(objectid)
end

Then(/^I( can)? authenticate with authn-k8s as "([^"]*)"( without cert and key)?$/) do |success, objectid, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  #username = [ namespace, objectid ].join('/')
  username = "host/conjur/authn-k8s/minikube/apps/#{namespace}/#{objectid}"

  cert = nocertkey ? nil : OpenSSL::X509::Certificate.new(@cert)
  key = nocertkey ? nil : @pkey

  begin
    @token = RestClient::Resource.new(
      authn_k8s_host,
      ssl_client_cert: cert,
      ssl_client_key: key,
      verify_ssl: OpenSSL::SSL::VERIFY_PEER
    )["#{ENV['CONJUR_ACCOUNT']}/#{CGI.escape username}/authenticate?request_ip=#{@request_ip}"].post(cert.to_s)
  rescue
    raise if success
    @error = $!
  end

  if @token
    expect(@token).to include("BEGIN PKCS7")
  end
end

Then(/^I( can)? authenticate pod matching "([^"]*)" with authn-k8s as "([^"]*)"( without cert and key)?$/) do |success, objectid, hostid, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  username = [ namespace, hostid ].join('/')

  cert = nocertkey ? nil : OpenSSL::X509::Certificate.new(@cert)
  key = nocertkey ? nil : @pkey

  begin
    @token = RestClient::Resource.new(authn_k8s_host, ssl_client_cert: cert, ssl_client_key: key, verify_ssl: OpenSSL::SSL::VERIFY_PEER)["users/#{CGI.escape username}/authenticate?request_ip=#{@request_ip}"].post('')
  rescue
    raise if success
    @error = $!
  end

  if @token
    expect(@token).to include("BEGIN PKCS7")
  end
end
