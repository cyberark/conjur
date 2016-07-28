Then(/^I list the public keys for ([\w_]+) "([^"]*)"$/) do |kind, id|
  invoke do
    possum.public_keys [ kind, id ].join(":")
  end
end
