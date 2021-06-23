# frozen_string_literal: true

Then("the {string} should be:") do |field, expected_json|
  _, kind, id = @result.body['id'].split(':')
  @client ||= Client.for("user", "admin")
  @result = api_response { @client.fetch_resource(kind: kind, id: id) }
  expect(@result.body[field]).to eq(JSON.parse(expected_json))
end
