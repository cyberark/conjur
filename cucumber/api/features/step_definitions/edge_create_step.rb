
Then(/^Edge name "([^"]*)" data exists in db$/) do |arg|
  puts "id is #{arg}"
  edge = Edge[name: arg]
  id = edge[:id]
  expect(edge).not_to be_nil

  res = Resource.where(Sequel.like(:resource_id, "cucumber:policy:edge/edge-#{id}")).count
  expect(res).to be > 0
  res = Resource.where(Sequel.like(:resource_id, "cucumber:host:edge/edge-#{id}/edge-host-#{id}")).count
  expect(res).to be > 0
  res = Resource.where(Sequel.like(:resource_id, "cucumber:host:edge/edge-installer-#{id}/edge-installer-host-#{id}"))
  expect(res).to be > 0
end
