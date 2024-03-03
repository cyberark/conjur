require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe StaticSecretsController, type: :request do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
  let(:bob_user) { Role.find_or_create(role_id: 'rspec:user:bob') }
  let(:rita_user) { Role.find_or_create(role_id: 'rspec:user:rita') }

  let(:expected_event_object) { instance_double(Audit::Event::Policy) }
  let(:log_object) { instance_double(::Audit::Log::SyslogAdapter, log: expected_event_object) }

  let(:test_policy) do
    <<~POLICY
      - !user alice
      - !user bob
      - !user rita      
      
      - !policy
        id: data
        body:
        - !policy secrets
        - !host host1
        - !group group1

        - !variable
          id: mySecret
          mime_type: text/plain 

        - !grant
           role: !group group1
           member:          
             - !host host1 

      - !permit
        role: !user alice
        privileges: [ read ]
        resource: !variable data/mySecret
    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    allow(Audit).to receive(:logger).and_return(log_object)

    init_slosilo_keys("rspec")
    # Load the test policy into Conjur
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        { 'RAW_POST_DATA' => test_policy }
      )
    )
    assert_response :success
  end

  describe "Permissions Validations for Create static secret" do
    context "Creating secret with different permissions on the policy" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1"
          }
        BODY
      end
      let(:permit_policy) do
        <<~POLICY
          - !permit
            resource: !policy secrets
            privilege: [ create ]
            role: !user /alice

          - !permit
            resource: !policy secrets
            privilege: [ update ]
            role: !user /bob
        POLICY
      end
      before do
        patch(
          '/policies/rspec/policy/data',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => permit_policy }
          )
        )
        assert_response :success
      end
      it 'Secret resource was created with update permissions' do
        post("/secrets/static",
             env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
      end
      it 'Secret resource fail to be created with create permissions' do
        post("/secrets/static",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :forbidden
      end
    end
  end

  describe "Create static secret with input errors" do
    context "when creating secret with not existent branch" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/no_secrets",
              "name": "secret1"
          }
        BODY
      end
      it 'Secret creation failed on 404' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :not_found
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Policy 'data/no_secrets' not found in account 'rspec'")
      end
    end
  end

  describe "Create static secret with permissions with input errors" do
    context "When creating secret with not valid subject id" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
               "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "luba"
                  },
                  "privileges": [ "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :not_found
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("User 'luba' not found in account 'rspec'")
      end
    end
  end

  describe "Create static secret" do
    context "with only name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1"
          }
        BODY
      end
      let(:variable_policy) do
        <<~POLICY
          - !variable secret2          
        POLICY
      end
      it 'Secret resource was created' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        expect(response.body).to eq('{"name":"secret1","branch":"/data/secrets"}')
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
        # correct header
        expect(response.headers['Content-Type'].include?(v2_api_header["Accept"])).to eq true
        # Secret resource is created
        resource = Resource["rspec:variable:data/secrets/secret1"]
        expect(resource).to_not be_nil
        expect(resource[:owner_id]).to eq "rspec:policy:data/secrets"
        expect(resource[:policy_id]).to eq "rspec:policy:data/secrets"
        # Verify that secret created by policy in same branch created the same
        patch(
          '/policies/rspec/policy/data/secrets',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => variable_policy }
          )
        )
        assert_response :success
        policy_resource = Resource["rspec:variable:data/secrets/secret2"]
        expect(policy_resource).to_not be_nil
        expect(resource[:owner_id]).to eq policy_resource[:owner_id]
        expect(resource[:policy_id]).to eq policy_resource[:policy_id]
        # Search for secret using search api
        get("/resources/rspec?kind=variable&search=secret1",
            env: token_auth_header(role: admin_user)
        )
        assert_response :success
        expect(response.body).to_not eq("[]")
        # Correct audit is returned
        #audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        #verify_audit_message(audit_message)
      end
      it 'Secret creation failed on 409 for existing secret' do
        # First secret creation
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created

        # Second secret creation
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :conflict
      end
    end
    context "with simple value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "value": "password"
          }
        BODY
      end
      it 'Secret value can be fetched' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"type\":\"static\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
        # Verify secret value can be fetched
        get('/secrets/rspec/variable/data/secrets/secret1',
            env: token_auth_header(role: admin_user)
        )
        assert_response :success
        expect(response.body).to eq("password")
      end
    end
    context "with empty value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "value": ""
          }
        BODY
      end
      it 'Secret value is not stored' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # Verify secret value can be fetched
        get('/secrets/rspec/variable/data/secrets/secret1',
            env: token_auth_header(role: admin_user)
        )
        assert_response :not_found
        secret = Secret["rspec:variable:data/secrets/secret1"]
        expect(secret).to be_nil
      end
    end
    context "without annotations" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "mime_type": "text/plain"
          }
        BODY
      end
      it 'Secret resource was created with default annotations' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_annotations\",\"type\":\"static\",\"mime_type\":\"text/plain\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
        # Secret resource is created with annotations
        annotations = Annotation.where(resource_id:"rspec:variable:data/secrets/secret_annotations").all
        expect(annotations.size).to eq 1
        expect(annotations[0][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[0][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[0][:name]).to eq "conjur/mime_type"
        expect(annotations[0][:value]).to eq "text/plain"
      end
    end
    context "with annotations" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
               "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "test_ann",
                  "value": "test"
                }             
              ]       
          }
        BODY
      end
      it 'Secret resource was created with default annotations and custom annotations' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_annotations\",\"type\":\"static\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"test_ann\",\"value\":\"test\"}],\"permissions\":\"[]\"}")
        # Secret resource is created with annotations
        annotations = Annotation.where(resource_id:"rspec:variable:data/secrets/secret_annotations").all
        expect(annotations.size).to eq 2
        expect(annotations[0][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[0][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[0][:name]).to eq "description"
        expect(annotations[0][:value]).to eq "desc"
        expect(annotations[1][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[1][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[1][:name]).to eq "test_ann"
        expect(annotations[1][:value]).to eq "test"
      end
    end
  end

  describe "Create static secret with permissions" do
    context "When giving permissions for a user" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_user_permissions",
               "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "read", "update"]
                }          
              ]       
          }
        BODY
      end
      it 'User Alice can update secret value and see the secret resource' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_user_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"read\",\"update\"]}],\"annotations\":\"[]\"}")
        # Secret resource is created with permissions
        permissions = Permission.where(resource_id:"rspec:variable:data/secrets/secret_user_permissions").all
        expect(permissions.size).to eq 2
        expect(permissions[0][:resource_id]).to eq "rspec:variable:data/secrets/secret_user_permissions"
        expect(permissions[0][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(permissions[0][:role_id]).to eq "rspec:user:alice"
        expect(permissions[0][:privilege]).to eq "read"
        expect(permissions[1][:resource_id]).to eq "rspec:variable:data/secrets/secret_user_permissions"
        expect(permissions[1][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(permissions[1][:role_id]).to eq "rspec:user:alice"
        expect(permissions[1][:privilege]).to eq "update"
        # Alice can set secret value (update permission)
        post("/secrets/rspec/variable/data/secrets/secret_user_permissions",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => "password",
                 'CONTENT_TYPE' => "text/plain"
               }
             )
        )
        assert_response :created
        # Alice can get variable (read permission)
        get("/resources/rspec/variable/data/secrets/secret_user_permissions",
             env: token_auth_header(role: alice_user)
        )
        assert_response :ok
      end
    end
    context "When giving permissions for a workload" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_workload_permissions",
              "value": "password",
               "permissions": [
                {
                  "subject": {
                    "kind": "host",
                    "id": "/data/host1"
                  },
                  "privileges": [ "execute", "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Workload can see the secret resource and the secret value' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_workload_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"host\",\"id\":\"/data/host1\"},\"privileges\":[\"execute\",\"read\"]}],\"annotations\":\"[]\"}")
        # Host can get variable (read permission)
        get("/resources/rspec/variable/data/secrets/secret_workload_permissions",
            env: token_auth_header(role: Role["rspec:host:data/host1"], is_user: false)
        )
        assert_response :ok
        #Host can get secret value (execute permissions)
        get("/secrets/rspec/variable/data/secrets/secret_workload_permissions",
             env: token_auth_header(role: Role["rspec:host:data/host1"], is_user: false)
        )
        assert_response :ok
      end
    end
    context "When giving permissions for a group" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_group_permissions",
               "permissions": [
                {
                  "subject": {
                    "kind": "group",
                    "id": "/data/group1"
                  },
                  "privileges": [ "execute", "update"]
                }          
              ]       
          }
        BODY
      end
      it 'Workload in a group can update the secret value and then see it' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_group_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"group\",\"id\":\"/data/group1\"},\"privileges\":[\"execute\",\"update\"]}],\"annotations\":\"[]\"}")
        # Host can set secret value (update permission)
        post("/secrets/rspec/variable/data/secrets/secret_group_permissions",
             env: token_auth_header(role: Role["rspec:host:data/host1"], is_user: false).merge(
               {
                 'RAW_POST_DATA' => "password",
                 'CONTENT_TYPE' => "text/plain"
               }
             )
        )
        assert_response :created
        #Host can get secret value (execute pemissions)
        get("/secrets/rspec/variable/data/secrets/secret_group_permissions",
            env: token_auth_header(role: Role["rspec:host:data/host1"], is_user: false)
        )
        assert_response :ok
        expect(response.body).to eq("password")
      end
    end
    context "When giving permissions for a group and user" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_permissions",
               "permissions": [
                {
                  "subject": {
                    "kind": "group",
                    "id": "/data/group1"
                  },
                  "privileges": [ "execute"]
                },
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "update"]
                }           
              ]       
          }
        BODY
      end
      it 'Workload in a group can update the secret value and then see it' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"group\",\"id\":\"/data/group1\"},\"privileges\":[\"execute\"]},{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"update\"]}],\"annotations\":\"[]\"}")
        # User can set secret value (update permission)
        post("/secrets/rspec/variable/data/secrets/secret_permissions",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => "password",
                 'CONTENT_TYPE' => "text/plain"
               }
             )
        )
        assert_response :created
        #Host can get secret value (execute pemissions)
        get("/secrets/rspec/variable/data/secrets/secret_permissions",
            env: token_auth_header(role: Role["rspec:host:data/host1"], is_user: false)
        )
        assert_response :ok
        expect(response.body).to eq("password")
      end
    end
  end

  describe 'Get existing variable' do
    context 'when the user has read permission' do
      it 'returns 200' do
        get(
          '/secrets/static/data/mySecret',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :success
        validate_response('mySecret', 'data', 'text/plain')
      end
    end
    context 'when the user does not have read permission' do
      it 'returns 403' do
        get(
          '/secrets/static/data/mySecret',
          env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :forbidden
      end
    end
    context 'when the user creates and gets static secrets using v2 apis' do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1"
          }
        BODY
      end
      it 'returns 200' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created

        get(
          '/secrets/static/data/secrets/secret1',
          env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :success
        validate_response('secret1', 'data/secrets', nil)
      end
    end
  end

  describe 'Get non existing variable' do
    context 'when the user has read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/data/doesNotExist',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found
      end
    end
    context 'when the user does not have read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/data/doesNotExist',
          env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found
      end
    end
  end

  describe 'Get variable with invalid branch' do
    context 'when the user has read permission' do
      it 'returns 404' do
        get(
          '/secrets/static/doesNotExist/mySecret',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :not_found
      end
    end
  end

  def validate_response(name, branch, mime_type)
    response_body = JSON.parse(response.body)
    expect(response_body['name']).to eq(name)
    expect(response_body['branch']).to eq(branch)
    if mime_type
      expect(response_body['mime_type']).to eq(mime_type)
    end
  end
end
