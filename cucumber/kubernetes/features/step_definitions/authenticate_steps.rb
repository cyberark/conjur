def conjur_resource_id(namespace, resource_id)
  "host/conjur/authn-k8s/minikube/apps/#{namespace}/#{resource_id}"
end

def gen_cert(host_id)
  username = [namespace, host_id].join('/')
  webservice_resource_id = "#{ENV['CONJUR_ACCOUNT']}:webservice:#{username}"
  role_id = "#{ENV['CONJUR_ACCOUNT']}:policy:#{username}"
  Role.create(role_id: role_id)
  Resource.create(
    resource_id: "#{ENV['CONJUR_ACCOUNT']}:variable:#{username}/ca/cert",
    owner_id: role_id
  )
  Resource.create(
    resource_id: "#{ENV['CONJUR_ACCOUNT']}:variable:#{username}/ca/key",
    owner_id: role_id
  )
  ::Repos::ConjurCA.create(webservice_resource_id)
end

def authenticate_k8s(host, cert, key, conjur_id)
  conjur_id = substitute!(conjur_id)

  RestClient::Resource.new(
    host,
    ssl_ca_file: './nginx.crt',
    ssl_client_cert: cert,
    ssl_client_key: key,
    verify_ssl: OpenSSL::SSL::VERIFY_PEER
  )["#{ENV['CONJUR_ACCOUNT']}/#{CGI.escape(conjur_id)}/authenticate?request_ip=#{@request_ip}"].post('')
end

Given(/^I use the IP address of(?: a pod in)? "([^"]*)"$/) do |objectid|
  @request_ip = find_matching_pod(objectid)
end

Then(/^I( can)? authenticate with authn-k8s as "([^"]*)"( without cert and key)?$/) do |success, objectid, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  conjur_id = conjur_resource_id(namespace, objectid)

  cert = nil
  unless nocertkey
    expect(@cert.to_s).not_to be_empty, "ERROR: Certificate fetched was empty or nil but was expected to be present!"
    cert = OpenSSL::X509::Certificate.new(@cert)
  end

  key = nocertkey ? nil : @pkey

  begin
    response = authenticate_k8s(authn_k8s_host, cert, key, conjur_id)
  rescue
    raise if success

    @error = $!
  end

  unless response.nil?
    token = ConjurToken.new(response.body)
    expect(token.username).to eq(conjur_id)
  end
end

Then(/^I( can)? authenticate pod matching "([^"]*)" with authn-k8s as "([^"]*)"(?: with prefix "([^"]*)")?( without cert and key)?$/) do |success, objectid, hostid_suffix, hostid_prefix, nocertkey|
  @request_ip ||= detect_request_ip(objectid)

  conjur_id = conjur_resource_id(namespace, hostid_suffix)
  if hostid_prefix
    conjur_id = "#{hostid_prefix}/#{hostid_suffix}"
  end

  cert = nocertkey ? nil : OpenSSL::X509::Certificate.new(@cert)
  key = nocertkey ? nil : @pkey

  begin
    response = authenticate_k8s(authn_k8s_host, cert, key, conjur_id)
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

  conjur_id = conjur_resource_id(namespace, host_id)

  cert = gen_cert(host_id)

  begin
    authenticate_k8s(authn_k8s_host, cert, @pkey, conjur_id)
  rescue RestClient::Exception
    @error = $!
  end

  expect(@error.http_code).to eq(401)
end
