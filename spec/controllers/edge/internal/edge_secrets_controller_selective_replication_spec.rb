require 'spec_helper'

describe EdgeSecretsController, :type => :request do
  let(:account) { "rspec" }
  let(:edge_hosts_policy) do
    <<~POLICY
    - !policy
      id: edge
      body:
        - !group edge-hosts
        - !policy   
            id: edge-abcd1234567890
            body: 
            - !host
              id: edge-host-abcd1234567890
              annotations:
                authn/api-key: true
            - !host
              id: edge-host-abcd1234567891
              annotations:
                authn/api-key: true
  
    - !grant
       role: !group edge/edge-hosts
       members: 
         - !host edge/edge-abcd1234567890/edge-host-abcd1234567890
         - !host edge/edge-abcd1234567890/edge-host-abcd1234567891
    - !group Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      member: !user admin
    - !policy
      id: data
      body:
        - !variable secret1
        - !variable secret2
        - !variable secret3
        - !variable secret4
        - !variable secret5'
    - !permit
      role: !group edge/edge-hosts
      privileges: [ read, execute ]
      resource: !variable data/secret1
    POLICY
  end
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:host_id) {}
  before do
    ENV['SELECTIVE_REPLICATION_ENABLED'] = 'true'
    init_slosilo_keys("rspec")
    @alice_user = Role.find_or_create(role_id: 'rspec:user:alice')
    put(
      "/policies/rspec/policy/root",
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => edge_hosts_policy
      )
    )
    assert_response :success
    Secret.create(resource_id: "rspec:variable:data/secret1", value: "value")
    Secret.create(resource_id: "rspec:variable:data/secret2", value: "value")
    Secret.create(resource_id: "rspec:variable:data/secret3", value: "value")
    Secret.create(resource_id: "rspec:variable:data/secret4", value: "value")
    Secret.create(resource_id: "rspec:variable:data/secret5'", value: "value")
    @current_host = Role.find_or_create(role_id: "rspec:host:edge/edge-abcd1234567890/edge-host-abcd1234567890")
  end
  context "Selective Replication expected responses" do
    it "replicate only those who permitted to - only data/secret1" do
      get("/edge/secrets/rspec", env: token_auth_header(role: @current_host, is_user: false))
      expect(response.code).to eq("200")
      parsed_body = JSON.parse(response.body)
      expect(parsed_body["secrets"]).to be_an_instance_of(Array)
      result = parsed_body["secrets"]
      expect(result.length).to eq(1)
      expect(result[0]["id"]).to eq("rspec:variable:data/secret1")
      secret = result[0]
      permissions = secret["permissions"]
      expect(permissions[0]["privilege"]).to eq("execute")
      expect(permissions[0]["resource"]).to eq("rspec:variable:data/secret1")
      expect(permissions[0]["role"]).to eq("rspec:group:edge/edge-hosts")
      expect(result[0]["value"]).to eq("value")
      expect(result[0]["version"]).to eq("1")
    end

    let(:add_host_to_group) do
      <<~POLICY
         - !policy
           id: data
           body:
           - !group data-hosts
         - !grant
           role: !group data/data-hosts
           members:  
           - !host edge/edge-abcd1234567890/edge-host-abcd1234567891
         - !permit
           role: !group data/data-hosts
           privileges: [ read, execute ]
           resource: !variable data/secret2
         - !permit
           role: !group edge/edge-hosts
           privileges: [ read, execute ]
           resource: !variable data/secret3 
        POLICY
    end
    it "check different groups" do
      post(
        "/policies/rspec/policy/root",
        env: token_auth_header(role: admin_user).merge(
          'RAW_POST_DATA' => add_host_to_group
        )
      )
      assert_response :success
      @current_host1 = Role.find_or_create(role_id: "rspec:host:edge/edge-abcd1234567890/edge-host-abcd1234567891")
      get("/edge/secrets/rspec", env: token_auth_header(role: @current_host1, is_user: false))
      parsed_body = JSON.parse(response.body)
      expect(response.code).to eq("200")
      expect(parsed_body["secrets"]).to be_an_instance_of(Array)
      result = parsed_body["secrets"]
      expect(result.length).to eq(3)
      secret1 = result[0]
      secret2 = result[1]
      secret3 = result[2]
      expect(secret1["id"]).to eq("rspec:variable:data/secret1")
      expect(secret2["id"]).to eq("rspec:variable:data/secret2")
      expect(secret3["id"]).to eq("rspec:variable:data/secret3")
      expect(secret1["permissions"][0]["role"]).to eq("rspec:group:edge/edge-hosts")
      expect(secret2["permissions"][0]["role"]).to eq("rspec:group:data/data-hosts")
      expect(secret3["permissions"][0]["role"]).to eq("rspec:group:edge/edge-hosts")
      get("/edge/secrets/rspec?count=true", env: token_auth_header(role: @current_host1, is_user: false))
      expect(response.code).to eq("200")
      parsed_body = JSON.parse(response.body)
      expect(response.code).to eq("200")
      expect(parsed_body["count"]).to eq(3)
    end
    it "check count selective" do
      get("/edge/secrets/rspec?count=true", env: token_auth_header(role: @current_host, is_user: false))
      parsed_body = JSON.parse(response.body)
      expect(response.code).to eq("200")
      expect(parsed_body["count"]).to eq(1)
    end
  end
end