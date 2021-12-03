# frozen_string_literal: true

Then(/^the resource list should include the newest resource$/) do
  expect(@result.map{|r| r['id']}).to include(@current_resource.id)
end

Then(/^the resource list should not include the newest resource$/) do
  expect(@result.map{|r| r['id']}).to_not include(@current_resource.id)
end

Then(/^the resource list should include the newest resources$/) do
  expect(@result.map{|r| r['id']}).to include(*@resources.values.map{|r| r.id})
end

Then(/^there are (\d+) "([^"]*)" in the response$/) do |occurrences, key|
  expect(@result[key].count).to eq(occurrences)
end

Then(/^the resource list should only include the searched resource$/) do
  expect(@result.map{|r| r['id']}).to eq([@current_resource.id])
end

Then(/^the resource list should only include the searched resources$/) do
  @result.map{|r| r['id']}.should =~ @searchable_resources.map{|r| r.id}
end

Then(/^I receive (\d+) resources$/) do |count|
  expect(@result.count).to eq(count.to_i)
end

Then(/^I receive a count of (\d+)$/) do |count|
  expect(@result).to have_key('count')
  expect(@result['count']).to eq(count.to_i)
end

Then(/^the resource list should( not)? contain "([^"]*)" "([^"]*)"$/) do |invert, kind, id|
  mode = invert ? :to_not : :to
  id = [ account, kind, id ].join(":")

  expect(@result.map{|r| r['id']}).send(mode, include(id))
end

Then(/^the result is empty$/) do
  expect(@result).to be_empty
end

Then(/^the text result is:$/) do |value|
  expect(@result).to be
  expect(@result.headers[:content_type]).to include("text/plain")
  expect(@result).to eq(value)
end

Then(/^the YAML result is:$/) do |value|
  expect(@result).to be
  expect(@result.headers[:content_type]).to include("text/yaml")
  expect(@result.to_s).to eq(value)
end

Then(/^the binary result is "([^"]*)"$/) do |value|
  expect(@result).to be
  expect(@result.headers[:content_type]).to eq("application/octet-stream")
  expect(@result).to eq(value)
end

Then(/^the binary result is preserved$/) do
  expect(@result).to be
  expect(@result.headers[:content_type]).to eq("application/octet-stream")
  expect(@result).to eq(@value)
end

Then(/^the content encoding is "([^"]*)"/) do |encoding|
  expect(@content_encoding).to eq(encoding)
end

Then(/^the binary data is preserved for "([^"]*)"$/) do |resource_id|
  data = Base64.decode64(@result[resource_id])
  expect(data).to eq(@value)
end
