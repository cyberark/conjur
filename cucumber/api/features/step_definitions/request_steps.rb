# frozen_string_literal: true

Given(/^I authorize the request with the host factory token$/) do
  expect(@host_factory_token).to be
  headers[:authorization] = %Q(Token token="#{@host_factory_token.token}")
end

Given(/^I set the "([^"]*)" header to "([^"]*)"$/) do |header, value|
  headers[header] = value
end

Given(/^I clear the "([^"]*)" header$/) do |header|
  headers[header] = nil
end

When(/^I( (?:can|successfully))? GET "([^"]*)"$/) do |can, path|
  try_request can do
    get_json path
  end
end

When(/^I GET "([^"]*)" with no default headers$/) do |path|
  get_json_no_accept_header(path)
end

When(/^I( (?:can|successfully))? PUT "([^"]*)"$/) do |can, path|
  try_request can do
    put_json path
  end
end

# TODO: Remove the hack to avoid ambiguous match with one below it
When('I do DELETE "\/host_factory_tokens\/{host_factory_token}"') do |hf|
  try_request true do
    delete_json "/host_factory_tokens/#{hf}"
  end
end

# TODO: Remove the hack to avoid ambiguous match with one below it
When('I try to DELETE "\/host_factory_tokens\/{host_factory_token}"') do |hf|
  try_request false do
    delete_json "/host_factory_tokens/#{hf}"
  end
end

When(/^I( (?:can|successfully))? DELETE "([^"]*)"$/) do |can, path|
  try_request can do
    delete_json path
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with authorized user$/) do |can, path|
  try_request can do
    get_json path, token: ConjurToken.new(@response_body)
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with parameters:$/) do |can, path, parameters|
  params = YAML.load(parameters)
  path = [ path, params.to_query ].join("?")
  try_request can do
    get_json path
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with(?: username "([^"]*)" and password "([^"]*)")?(?: and)?(?: plain text body "([^"]*)")?$/) do |can, path, username, password, body|
  try_request can do
    put_json path, body, user: username, password: password
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with username "([^"]*)" and password "([^"]*)"$/) do |can, path, username, password|
  try_request can do
    get_json_with_basic_auth(path, user: username, password: password)
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with body from file "([^"]*)"/) do |can, path, filename|
  absolute_path = "#{File.dirname(__FILE__)}/../support/#{filename}"
  File.open(absolute_path) do |file|
    try_request can do
      post_json path, file.read
    end
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with in-body params$/) do |can, path|
  try_request can do
    post_multipart_json path
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)"(?: with plain text body "([^"]*)")?$/) do |can, path, body|
  try_request can do
    post_json path, body
  end
end
# "/authn/cucumber/alice/authenticate" with no Content-Type and body ":cucumber:user:alice_api_key"
# And
When(/I can authenticate Alice with no Content-Type header/) do
  try_request true do
    post_json(
      "/authn/cucumber/alice/authenticate",
      ":cucumber:user:alice_api_key"
    )
  end
end

When(/^I can authenticate Alice when Content-Type header has value "([^"]*)"$/) do |value|
  headers['Content-Type'] = value
  try_request true do
    post_json(
      "/authn/cucumber/alice/authenticate",
      ":cucumber:user:alice_api_key"
    )
  end
end

When(/^I( (?:successfully|can))? authenticate Alice (?:(\d+) times? in (\d+) threads? )?with Accept-Encoding header "([^"]*)"(?: with plain text body "([^"]*)")?$/) do |can, requests_num, threads_num, header, body|
  body ||= ":cucumber:user:alice_api_key"
  requests_num ||= 1
  threads_num ||= 1
  authenticate_with_performance(
    requests_num,
    threads_num,
    authentication_func: :authn_request,
    authentication_func_params: {
      url: "/authn/cucumber/alice/authenticate",
      api_key: body,
      encoding: header,
      can: can
    }
  )
end

When(/^I( (?:can|successfully))? POST(( \d+) times)? "([^"]*)" with body:$/) do |can, requests_num, path, body|
  requests_num ||= 1

  (1..requests_num.to_i).each do
    try_request can do
      post_json path, body
    end
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with body:$/) do |can, path, body|
  try_request can do
    put_json path, body
  end
end

When(/^I( (?:can|successfully))? PATCH "([^"]*)" with body:$/) do |can, path, body|
  try_request can do
    patch_json path, body
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with parameters:$/) do |can, path, parameters|
  params = YAML.load(parameters)
  try_request can do
    post_json path, params
  end
end

When(/^I( ?:can|successfully)? authenticate as "([^"]*)" with account "([^"]*)"/) do |can, login, account|
  user = lookup_user(login, account)
  user.reload

  try_request can do
    post_json "/authn/#{account}/#{login}/authenticate", user.api_key
  end
end

Then(/^the result is an API key$/) do
  expect(@result).to be
  expect(@result.length).to be > 40
  expect(@result).to match(/^[a-z0-9]+$/)
end

Then(/^the result is the API key for ([^"]*) "([^"]*)"$/) do |kind, login|
  case kind
  when "user"
    role = lookup_user(login)
  when "host"
    role = lookup_host(login)
  else
    raise ArgumentError, "Invalid role kind. Function accepts 'host' or 'user'"
  end

  role.reload
  expect(role.credentials).to be
  expect(@result).to eq(role.credentials.api_key)
end

Then(/^it's confirmed$/) do
  expect(@http_status).to be_blank
end

Then(/^the HTTP response status code is (\d+)$/) do |code|
  expect(@http_status).to eq(code.to_i)
end

Then(/^the HTTP response content type is "([^"]*)"$/) do |content_type|
  expect(@content_type).to match(content_type)
end

Then(/^the HTTP response is base64 encoded$/) do
  expect(@result.headers[:content_encoding]).to eq("base64")

  # Override encoded response with decode one to use other helpers
  @response_body = Base64.strict_decode64(@result)
  expect(JSON.parse(@response_body).is_a?(Hash)).to be(true)
end

Then(/^the result is true$/) do
  expect(@result).to be(true)
end

Then(/^the result is false$/) do
  expect(@result).to be(false)
end

Then(/^I (?:can )*authenticate with the admin API key for the account "(.*?)"/) do |account|
  user = lookup_user('admin', account)
  user.reload
  steps %Q{
    Then I can POST "/authn/#{account}/admin/authenticate" with plain text body "#{user.api_key}"
  }
  steps %Q{
    And I can GET "/authn/#{account}/login" with username "admin" and password "#{user.api_key}"
  }
end

Then(/^I save the response as "(.+)"$/) do |name|
  @saved_results = @saved_results || {}
  @saved_results[name] = @result
end

# TODO: is it right place?  This is ugly right now...
# TODO: the host factory and other concern need to be split apart
Then("our JSON should be:") do |json|
  @result.delete('created_at')
  if @response_api_key
    json = json.gsub("@response_api_key@", @response_api_key)
  end
  json = render_hf_token_and_expiration(json)
  expect(@result).to eq(JSON.parse(json))
end

# TODO: we need a better refactoring for this
Then("the host factory JSON should be:") do |json|
  @result.delete('created_at')
  token = @result.dig('tokens', 0)
  if token
    json = json.gsub("@host_factory_token@", token['token'])
    json = json.gsub(
      "@host_factory_token_expiration@",
      parse_expiration(token['expiration'])
    )
  end
  expect(@result).to eq(JSON.parse(json))
end
