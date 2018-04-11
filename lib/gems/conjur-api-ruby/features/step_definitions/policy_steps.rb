Given(/^a new user$/) do
  @user_id = "user-#{random_hex}"
  @public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd/PAcCL9rW/zAS7DRns/KYiAvRAEKxBu/0IF32z7x6YiMFcA2hmH4DMYaIY45Xlj7L9uTZamUlRZNjSS9Xm6Lhh7XGceIX2067/MDnH+or9xh5LZs6gb3x7QVtNz26Au5h5kP0xoJ+wpVxvY707BeSax/WQZI8akqd0fD1IqOoafWkcX0ucu5iIgDh08R7zq3vrDHEK7+SoYo9ncHfmOUJ5lmImGiU/WMqM0OzN3RsgxJi/aaHjW1IASTY8TmAtTtjEsxbQXxRVUCAP9vWUZg7p3aqIB6sEP8skgncCUtHBQxUtE1XN8Q8NeFOzau6+9sQTXlPl8c/L4Jc4K96C75 #{@user_id}@example.com"
  response = $conjur.load_policy 'root', <<-POLICY
  - !user
    id: #{@user_id}
    uidnumber: 1000
    public_keys:
    - #{@public_key}
  POLICY
  @user = $conjur.resource("cucumber:user:#{@user_id}")
  @user_api_key = response.created_roles["cucumber:user:#{@user_id}"]['api_key']
  expect(@user_api_key).to be
end

Given(/^a new group$/) do
  @group_id = "group-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !group
    id: #{@group_id}
    gidnumber: 1000
  POLICY
  @group = $conjur.resource("cucumber:group:#{@group_id}")
end

Given(/^a new host$/) do
  @host_id = "app-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !host #{@host_id}
  POLICY
  @host_api_key = response.created_roles["cucumber:host:#{@host_id}"]['api_key']
  expect(@host_api_key).to be
  @host = $conjur.resource("cucumber:host:#{@host_id}")
  @host.attributes['api_key'] = @host_api_key
end
