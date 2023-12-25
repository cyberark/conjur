
Then(/^Edge name "([^"]*)" data exists in db$/) do |arg|
  edge = Edge[name: arg]
  id = edge[:id]
  expect(edge).not_to be_nil

  res = Resource.where(Sequel.like(:resource_id, "cucumber:policy:edge/edge-#{id}")).count
  expect(res).to be > 0
  res = Resource.where(Sequel.like(:resource_id, "cucumber:host:edge/edge-#{id}/edge-host-#{id}")).count
  expect(res).to be > 0
  res = Resource.where(Sequel.like(:resource_id, "cucumber:host:edge/edge-installer-#{id}/edge-installer-host-#{id}")).count
  expect(res).to be > 0
end

Then(/^Edge id "([^"]*)" exists in db$/) do |id|
  edge = Edge[id: id]
  expect(edge).not_to be_nil
end

When(/^I login as the host associated with Edge "([^"]*)"$/) do |edge_name|
  edge = Edge[name: edge_name]
  hostname = edge.get_edge_host_name("cucumber")
  @current_user = Role.with_pk!(hostname)
  Credentials.new(role: @current_user).save unless @current_user.credentials
end

After do |scenario|
  Edge.dataset.delete
end
