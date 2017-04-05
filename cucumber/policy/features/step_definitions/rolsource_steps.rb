Given(/^I show the ([\w_]+) "([^"]*)"$/) do |kind, id|
  invoke do
    resource_data = possum.resource_show [ kind, id ].join(":")
    role_data = begin
      possum.role_show [ kind, id ].join(":")
    rescue Possum::UnexpectedResponseError
      {}
    end
    resource_data.merge role_data
  end
end
