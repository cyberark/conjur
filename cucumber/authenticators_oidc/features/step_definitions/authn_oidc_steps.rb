Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{@scenario_context.get(:oidc_provider_internal_uri)}/token"
  payload = {
    grant_type: 'password',
    username: username,
    password: password,
    scope: @scenario_context.get(:oidc_scope)
  }
  options = {
    user: @scenario_context.get(:oidc_client_id),
    password: @scenario_context.get(:oidc_client_secret)
  }

  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/I fetch a code for username "([^"]*)" and password "([^"]*)" from "([^"]*)"/) do |username, password, service_id|
  Rails.application.config.conjur_config.authenticators = ["authn-oidc/#{service_id}"]

  # Retrieve the specified authenticator provider
  provider = JSON.parse(
    Net::HTTP.get(
      URI("#{conjur_hostname}/authn-oidc/cucumber/providers")
    )
  ).first { |p| p['service_id'] == service_id }

  @scenario_context.add(:nonce, provider['nonce'])

  # The version of Keycloak we're using does not accept PKCE. We need
  # to strip code challenge and code challenge method from the redirect
  # URI
  redirect_uri = URI.parse(provider['redirect_uri'])
  params = URI.decode_www_form(redirect_uri.query).to_h
  params.delete('code_challenge')
  params.delete('code_challenge_method')
  redirect_uri.query = URI.encode_www_form(params)

  http = Net::HTTP.new(redirect_uri.host, redirect_uri.port)
  # Enable SSL support
  http.use_ssl = true
  # Don't verify (to simplify self-signed certificate)
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new("#{redirect_uri.path}?#{redirect_uri.query}")
  response = http.request(request)

  raise response if response.is_a?(Net::HTTPError) || response.is_a?(Net::HTTPClientError)

  all_cookies = response.get_fields('set-cookie')
  cookies_arrays = Array.new
  all_cookies.each do |cookie|
    cookies_arrays.push(cookie.split('; ')[0])
  end

  html = Nokogiri::HTML(response.body)
  post_uri = URI(html.xpath('//form').first.attributes['action'].value)

  http = Net::HTTP.new(post_uri.host, post_uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(post_uri.request_uri)
  request['Cookie'] = cookies_arrays.join('; ')
  request.set_form_data({ 'username' => username, 'password' => password })

  response = http.request(request)

  @scenario_context.set(:code, nil)
  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location']).each do |key, value|
      @scenario_context.set(key, value)
    end
  end
end

Given(/^I load a policy and enable an oidc user into group "([^"]*)":/) do |group, policy|
  user_policy = """
  - !user #{@scenario_context.get(:oidc_username)}

  - !grant
    role: !group #{group}
    member: !user #{@scenario_context.get(:oidc_username)}"""

  load_root_policy(policy + user_policy)
end

Given(/^I retrieve OIDC configuration from the provider endpoint for "([^"]*)"/) do |service_id|
  provider = JSON.parse(
    Net::HTTP.get(
      URI("#{conjur_hostname}/authn-oidc/cucumber/providers")
    )
  ).first { |p| p['service_id'] == service_id }
  @scenario_context.add(:nonce, provider['nonce'])
  @scenario_context.add(:code_verifier, provider['code_verifier'])
  @scenario_context.add(:redirect_uri, provider['redirect_uri'])
end

Given(/^I authenticate and fetch a code from Identity/) do
  # A request to /Security/StartAuthentication begins the login process,
  # and returns a list of authentication mechanisms to engage with.

  token = ""
  host = URI(@scenario_context.get(:redirect_uri)).host
  resp = start_auth_request(host, @scenario_context.get(:oidc_username))
  resp_h = JSON.parse(resp.body)

  if resp_h["Result"]["PodFqdn"]
    resp = start_auth_request(resp_h["Result"]["PodFqdn"], @scenario_context.get(:oidc_username))
    resp_h = JSON.parse(resp.body)
  end

  raise "Failed to retrieve OIDC code status: #{resp.code}" unless resp_h["success"]

  session_id = resp_h["Result"]["SessionId"]
  challenges = resp_h["Result"]["Challenges"]

  # Usually, we would iterate through MFA challenges sequentially.
  # For our purposes, though, we want to make sure to use the Password
  # and Mobile Authenticator mechanisms.

  password_mechanism = challenges[0]["Mechanisms"].detect { |m| m["PromptSelectMech"] == "Password" }

  # Advance Password-based authentication handshake.

  password_body = JSON.generate({
    "Action": "Answer",
    "Answer": @scenario_context.get(:oidc_password),
    "MechanismId": password_mechanism["MechanismId"],
    "SessionId": session_id
  })
  resp = advance_auth_request(host, password_body)
  resp_h = JSON.parse(resp.body)
  raise "Failed to advance authentication: #{resp_h['Message']}" unless resp_h["success"]


  # If only one challenge, then the response should contain the bearer token.
  if challenges.length == 1
    cookies = resp.get_fields('Set-Cookie')
    token_cookie = cookies.detect { |c| c.start_with?(".ASPXAUTH") }
    token = token_cookie.split('; ')[0].split('=')[1]
    if token == ""
      raise "Failed to advance authentication: please reattempt"
    end
  else
    # Engaging with a Mobile Auth and polling for out-of-band authentication
    # success is included temporarily, and is required for users that are required
    # to perform MFA. Before merging, and service account should be made available
    # for running this test in CI, and the account should not be bound by MFA.
    mobile_auth_mechanism = challenges[1]["Mechanisms"].detect { |m| m["PromptSelectMech"] == "Mobile Authenticator" }
    mobile_auth_body = JSON.generate({
      "Action": "StartOOB",
      "MechanismId": mobile_auth_mechanism["MechanismId"],
      "SessionId": session_id
    })
    resp = advance_auth_request(host, mobile_auth_body)
    resp_h = JSON.parse(resp.body)
    raise "Failed to advance authentication: #{resp_h['Message']}" unless resp_h["success"]

    puts "Dev env users: select #{resp_h['Result']['GeneratedAuthValue']} in your Identity notification"

    # For 30 seconds, Poll for out-of-band authentication success.

    poll_body = JSON.generate({
      "Action": "Poll",
      "MechanismId": mobile_auth_mechanism["MechanismId"],
      "SessionId": session_id
    })

    current = Time.current
    while Time.current < current + 30
      resp = advance_auth_request(host, poll_body)
      resp_h = JSON.parse(resp.body)

      next unless resp_h["Result"]["Summary"] == "LoginSuccess"

      cookies = resp.get_fields('Set-Cookie')
      token_cookie = cookies.detect { |c| c.start_with?(".ASPXAUTH") }
      token = token_cookie.split('; ')[0].split('=')[1]
    end
    if token == ""
      raise "Failed to advance authentication: please reattempt"
    end
  end
  
  # Make request to /Authorization endpoint with bearer token.
  target = URI("#{@scenario_context.get(:redirect_uri)}&state=test-state")
  resp = nil
  until target.to_s.include?("localhost:3000/authn-oidc/identity/cucumber")
    http = Net::HTTP.new(target.host, 443)
    http.use_ssl = true
    req = Net::HTTP::Get.new(target.request_uri)
    req['Accept'] = '*/*'
    req['Authorization'] = "Bearer #{token}"
    resp = http.request(req)

    target = URI(resp['location'].to_s)
  end

  if resp.is_a?(Net::HTTPRedirection)
    parse_oidc_code(resp['location']).each do |key, value|
      @scenario_context.set(key, value)
    end
  else
    raise "Failed to retrieve OIDC code status: #{resp.code}"
  end
end

Given(/^I authenticate and fetch a code from Okta/) do
  uri = URI("https://#{URI(@scenario_context.get(:redirect_uri)).host}/api/v1/authn")
  body = JSON.generate({ username: @scenario_context.get(:oidc_username), password: @scenario_context.get(:oidc_password) })

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request['Accept'] = 'application/json'
  request['Content-Type'] = 'application/json'
  request.body = body

  response = http.request(request)
  session_token = JSON.parse(response.body)["sessionToken"]

  uri = URI("#{@scenario_context.get(:redirect_uri)}&state=test-state&sessionToken=#{session_token}")
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location']).each do |key, value|
      @scenario_context.set(key, value)
    end
  else
    raise "Failed to retrieve OIDC code status: #{response.code}"
  end
end

When(/^I authenticate via OIDC V2 with code$/) do
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    code: @scenario_context.get(:code),
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.key?(:code_verifier) ? @scenario_context.get(:code_verifier) : nil
  )
end

When(/^I authenticate via OIDC V2 with code "([^"]*)"$/) do |code|
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    code: code,
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.key?(:code_verifier) ? @scenario_context.get(:code_verifier) : nil
  )
end

When(/^I authenticate via OIDC V2 with no code in the request$/) do
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: AuthnOidcHelper::ACCOUNT,
    code: nil,
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.key?(:code_verifier) ? @scenario_context.get(:code_verifier) : nil
  )
end

When(/^I authenticate via OIDC with id token$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with id token in header$/) do
  authenticate_id_token_with_oidc_in_header(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC V2 with code and service-id "([^"]*)"$/) do |service_id|
  authenticate_code_with_oidc(
    service_id: service_id,
    account: AuthnOidcHelper::ACCOUNT,
    code: @scenario_context.get(:code),
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.key?(:code_verifier) ? @scenario_context.get(:code_verifier) : nil
  )
end

Then(/^the OIDC user has been authorized by conjur/) do
  username = @scenario_context.get(:oidc_username)
  expect(retrieved_access_token.username).to eq(username)
end

Then(/^user "(\S+)" has been authorized by Conjur for (\d+) (\S+)$/) do |username, duration, duration_unit|
  token = retrieved_access_token
  expect(token.username).to eq(username)

  case duration_unit
  when /hours?/
    expected_duration = duration * 3600
  when /minutes?/
    expected_duration = duration * 60
  when /seconds?/
    expected_duration = duration
  end
  expect(token.duration).to eq(expected_duration)
end

When(/^I authenticate via OIDC with id token and without a service-id$/) do
  authenticate_id_token_with_oidc(
    service_id: nil,
    account: AuthnOidcHelper::ACCOUNT
  )
end

When(/^I authenticate via OIDC with id token and account "([^"]*)"$/) do |account|
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: account
  )
end

When(/^I authenticate via OIDC V2 with code and account "([^"]*)"$/) do |account|
  authenticate_code_with_oidc(
    service_id: "#{AuthnOidcHelper::SERVICE_ID}2",
    account: account,
    code: @scenario_context.get(:code),
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.get(:code_verifier)
  )
end

When(/^I authenticate via OIDC with code and service_id "([^"]*)"$/) do |service_id|
  authenticate_code_with_oidc(
    service_id: service_id,
    account: AuthnOidcHelper::ACCOUNT,
    code: @scenario_context.get(:code),
    nonce: @scenario_context.get(:nonce),
    code_verifier: @scenario_context.get(:code_verifier)
  )
end

When(/^I authenticate via OIDC with no id token( and user id "([^"]*)" in the request)?$/) do |user_id|
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT,
    id_token: nil,
    user_id: user_id
  )
end

When(/^I authenticate via OIDC with empty id token$/) do
  authenticate_id_token_with_oidc(
    service_id: AuthnOidcHelper::SERVICE_ID,
    account: AuthnOidcHelper::ACCOUNT,
    id_token: ""
  )
end

When(/^I authenticate (\d+) times? in (\d+) threads? via OIDC with( invalid)? id token$/) do |num_requests, num_threads, is_invalid|
  id_token = is_invalid ? invalid_id_token : parsed_id_token

  authenticate_with_performance(
    num_requests,
    num_threads,
    authentication_func: :authenticate_id_token_with_oidc,
    authentication_func_params: {
      service_id: AuthnOidcHelper::SERVICE_ID,
      account: AuthnOidcHelper::ACCOUNT,
      id_token: id_token
    }
  )
end
