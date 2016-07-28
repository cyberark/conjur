Then(/^the resource list should have the new resource$/) do
  expect(@result.map{|r| r['id']}).to include(@current_resource.id)
end

Then(/^the resource list should not have the new resource$/) do
  expect(@result.map{|r| r['id']}).to_not include(@current_resource.id)
end
