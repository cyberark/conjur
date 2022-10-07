Given('I set conjur variables') do |table|
  client = Client.for("user", "admin")
  table.hashes.each do |variable_hash|
    # Use environment variable if set
    if variable_hash['environment_variable'].present?
      variable_name = variable_hash['environment_variable']
      value = ENV[variable_name]
      if value.blank?
        raise "Environment variable: '#{variable_name}' must be set"
      end
    # Otherwise, use provided value
    else
      value = variable_hash['value']
    end

    client.add_secret(
      id: variable_hash['variable_id'],
      value: value
    )
  end
end

Given(/I fetch an ID Token for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  path = "#{oidc_provider_internal_uri}/token"
  payload = { grant_type: 'password', username: username, password: password, scope: oidc_scope }
  options = { user: oidc_client_id, password: oidc_client_secret }
  execute(:post, path, payload, options)

  parse_oidc_id_token
end

Given(/I fetch a code for username "([^"]*)" and password "([^"]*)"/) do |username, password|
  Rails.application.config.conjur_config.authenticators = ['authn-oidc/keycloak2']

  client = Client.for('user', 'admin')
  provider = JSON.parse(client.fetch_authenticators).first

  #  Save Nonce & Code Verifier for future use
  @context.set(
    nonce: provider['nonce'],
    code_verifier: provider['code_verifier'],
    service_id: provider['service_id']
  )

  response = Net::HTTP.get_response(URI(provider['redirect_uri']))
  raise response if response.is_a?(Net::HTTPError) || response.is_a?(Net::HTTPClientError)

  all_cookies = response.get_fields('set-cookie')
  cookies_arrays = []
  all_cookies.each do |cookie|
    cookies_arrays.push(cookie.split('; ')[0])
  end

  html = Nokogiri::HTML(response.body)
  post_uri = URI(html.xpath('//form').first.attributes['action'].value)

  http = Net::HTTP.new(post_uri.host, post_uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(post_uri.request_uri)
  request['Cookie'] = cookies_arrays.join('; ')
  request.set_form_data({'username' => username, 'password' => password})

  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    redirect = URI(response['location'])
    code = redirect.query.split('&').find{|i| i.split('=')[0] == 'code' }.split('=').last
    # Save Code for future steps
    @context.set(code: code)
  end
end

Given(/^I add an Okta user/) do
  user_policy = """
  - !user #{ENV.fetch('OKTA_USERNAME')}

  - !grant
    role: !group conjur/authn-oidc/okta-2/users
    member: !user #{ENV.fetch('OKTA_USERNAME')}
  """
  @client ||= Client.for("user", "admin")
  @result = @client.update_policy(id: 'root', policy: user_policy)
end

Given(/^I fetch a code from Okta/) do
  client = Client.for('user', 'admin')
  provider = JSON.parse(client.fetch_authenticators).first

  #  Save Nonce & Code Verifier for future use
  @context.set(
    nonce: provider['nonce'],
    code_verifier: provider['code_verifier'],
    service_id: provider['service_id']
  )

  # Get a user session ID via the Okta `authn` endpoint
  provider_uri = URI(provider['redirect_uri'])
  uri = URI("https://#{provider_uri.host}/api/v1/authn")
  result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = { username: ENV['OKTA_USERNAME'], password: ENV['OKTA_PASSWORD'] }.to_json
    http.request(request)
  end

  # Authenticate using the previously retrieved Session Token
  session_token = JSON.parse(result.body)["sessionToken"]
  uri = URI("#{provider['redirect_uri']}&state=foo&sessionToken=#{session_token}")
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  if response.is_a?(Net::HTTPRedirection)
    parse_oidc_code(response['location'])
    redirect = URI(response['location'])
    code = redirect.query.split('&').find{|i| i.split('=')[0] == 'code' }.split('=').last
    # Save Code for future steps
    @context.set(code: code)
  else
    raise "Failed to retrieve OIDC code status: #{response.code}"
  end
end

Given(/^I successfully set OIDC variables$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
end

When(/^I authenticate via OIDC V2 with code$/) do
  authenticate_with_oidc_code(
    service_id: @context.get(:service_id),
    account: @context.get(:account),
    params: {
      code: @context.get(:code),
      nonce: @context.get(:nonce),
      code_verifier: @context.get(:code_verifier)
    }
  )
end

Given(/^I successfully set OIDC variables without a service-id$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri, "")
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property, "")
end

Given(/^I successfully set provider-uri variable$/) do
  create_oidc_secret("provider-uri", oidc_provider_uri)
end

When(/^I authenticate via OIDC V2 with code "([^"]*)"$/) do |code|
  authenticate_with_oidc_code(
    service_id: @context.get(:service_id),
    account: @context.get(:account),
    params: {
      code: code,
      nonce: @context.get(:nonce),
      code_verifier: @context.get(:code_verifier)
    }
  )
end

When(/^I authenticate via OIDC V2 with no code in the request$/) do
  authenticate_with_oidc_code(
    service_id: @context.get(:service_id),
    account: @context.get(:account),
    params: {
      code: nil,
      nonce: @context.get(:nonce),
      code_verifier: @context.get(:code_verifier)
    }
  )
end

Given(/^I successfully set provider-uri variable to value "([^"]*)"$/) do |provider_uri|
  create_oidc_secret("provider-uri", provider_uri)
end

Given(/^I successfully set id-token-user-property variable$/) do
  create_oidc_secret("id-token-user-property", oidc_id_token_user_property)
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
  authenticate_with_oidc_code(
    service_id: service_id,
    account: @context.get(:account),
    params: {
      code: @context.get(:code),
      nonce: @context.get(:nonce),
      code_verifier: @context.get(:code_verifier)
    }
  )
end

Then(/^The Okta user has been authorized by Conjur/) do
  username = ENV['OKTA_USERNAME']
  expect(retrieved_access_token.username).to eq(username)
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
  authenticate_with_oidc_code(
    service_id: @context.get(:service_id),
    account: account,
    params: {
      code: @context.get(:code),
      nonce: @context.get(:nonce),
      code_verifier: @context.get(:code_verifier)
    }
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
