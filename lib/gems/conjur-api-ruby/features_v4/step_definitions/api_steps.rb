Given(/^a new host$/) do
  @host_id = "app-#{random_hex}"
  host = Conjur::API.host_factory_create_host($token, @host_id)
  @host_api_key = host.api_key
  expect(@host_api_key).to be

  @host = $conjur.resource("cucumber:host:#{@host_id}")
  @host.attributes['api_key'] = @host_api_key
end

When(/^I(?: can)? run the code:$/) do |code|
  @result = eval(code).tap do |result|
    if ENV['DEBUG']
      puts result
    end
  end
end
