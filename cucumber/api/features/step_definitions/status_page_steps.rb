When(/^I GET the root route$/) do
  @response = RestClient.get(Conjur.configuration.appliance_url)
end

Then(/^the status page is reachable$/) do
  expect(@response.code).to eq(200)
  expect(@response.headers[:content_type]).to include("text/html")
  expect(@response.body).to include("Your Conjur CE server is running!")
end
