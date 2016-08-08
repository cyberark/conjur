Then(/^I can( not)? add a secret to ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  @value = SecureRandom.uuid
  status = fail ? 403 : :ok
  invoke status do
    possum.secret_add [ kind, id ].join(":"), @value
  end
end

Then(/^I can( not)? fetch a secret from ([\w_]+) resource "([^"]*)"$/) do |fail, kind, id|
  status = fail ? 403 : :ok
  invoke status do
    possum.secret_fetch [ kind, id ].join(":")
  end
end
