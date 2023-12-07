When('I GET {string}') do |path|
  @response =
    RestClient::Resource.new(
      "#{Conjur.configuration.appliance_url}#{path}",
      ssl_ca_file: './nginx.crt',
      headers: {
        "Authorization" => "Token token=\"#{admin_access_token}\""
      }
    ).get
end

Then('the HTTP response status code is {int}') do |code|
  expect(@response.code).to eq(code)
end

Then('the HTTP response content type is {string}') do |content_type|
  expect(@response.headers[:content_type]).to include(content_type)
end

Then('the authenticator status check succeeds') do
  expect(JSON.parse(@response)).to eql({ "status" => 'ok' })
end
