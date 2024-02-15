require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe V2SecretsController, type: :request do
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
        id: conjur/issuers
        body: []
      
      - !policy
        id: data
        body:
        - !policy ephemerals
        - !policy secrets
        - !host host1
        - !group group1

        - !grant
           role: !group group1
           member:          
             - !host host1 
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

  describe "Create static secret with only name" do
    context "When creating secret" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      let(:variable_policy) do
        <<~POLICY
          - !variable secret2          
        POLICY
      end
      it 'Secret resource was created' do
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"type\":\"static\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
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
        post("/secrets",
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
        post("/secrets",
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
    context "Creating secret with different permissions on the policy" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "type": "static"
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
        post("/secrets",
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
        post("/secrets",
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

  describe "Create secret with name validations" do
    context "when creating secret with empty name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: name")
      end
    end
    context "when creating secret without name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: name")
      end
    end
    context "when creating secret with name not string" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": 5,
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'name' parameter must be of 'type=String'")
      end
    end
    context "when creating secret with unsupported symbols in its name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "se#cret/not_valid ",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("Invalid 'name' parameter. Only the following characters are supported: A-Z, a-z, 0-9 and _")
      end
    end
    context "when creating secret with too long name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secretstoolongggggggggggggggggggggggggggggggggggggggggggggggg",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("'name' parameter length exceeded. Limit the length to 60 characters")
      end
    end
    context "when creating secret with all supported symbols in its name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "seCret0_5Name",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation succeeds' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :success
      end
    end
  end

  describe "Create static secret with input errors" do
    context "when creating secret with not existent branch" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/no_secrets",
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 404' do
        post("/secrets",
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
    context "when creating secret with empty branch" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "",
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: branch")
      end
    end
    context "when creating secret with branch not existent" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/no_secrets",
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 404' do
        post("/secrets",
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
    context "when creating secret with no branch" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: branch")
      end
    end
    context "when creating secret with branch not string" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": 5,
              "name": "secret1",
              "type": "static"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'branch' parameter must be of 'type=String'")
      end
    end
    context "when creating secret with wrong type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1",
              "type": "simple"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Secret type is unsupported")
      end
    end
    context "when creating secret with empty type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1",
              "type": ""
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: type")
      end
    end
    context "when creating secret with no type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: type")
      end
    end
    context "when creating secret with type not string" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1",
              "type": 5
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'type' parameter must be of 'type=String'")
      end
    end
    context "when creating secret with empty mime_type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1",
              "type": "static",
              "mime_type": ""
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: mime_type")
      end
    end
    context "when creating secret with mime_type not string" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/secrets",
              "name": "secret1",
              "type": "static",
              "mime_type": 5
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'mime_type' parameter must be of 'type=String'")
      end
    end
  end

  describe "Create static secret with value" do
    context "when creating secret with simple value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "type": "static",
              "value": "password"
          }
        BODY
      end
      it 'Secret value can be fetched' do
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"type\":\"static\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
        # Verify secret value can be fetched
        get('/secrets/rspec/variable/data/secrets/secret1',
          env: token_auth_header(role: admin_user)
        )
        assert_response :success
        expect(response.body).to eq("password")
      end
    end
    context "when creating secret with empty value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret1",
              "type": "static",
              "value": ""
          }
        BODY
      end
      it 'Secret value is not stored' do
        post("/secrets",
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
  end

  describe "Create static secret with annotations" do
    context "When creating secret without annotations" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
              "mime_type": "text/plain"
          }
        BODY
      end
      it 'Secret resource was created with default annotations' do
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_annotations\",\"type\":\"static\",\"mime_type\":\"text/plain\",\"annotations\":\"[]\",\"permissions\":\"[]\"}")
        # Secret resource is created with annotations
        annotations = Annotation.where(resource_id:"rspec:variable:data/secrets/secret_annotations").all
        expect(annotations.size).to eq 2
        expect(annotations[0][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[0][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[0][:name]).to eq "conjur/kind"
        expect(annotations[0][:value]).to eq "static"
        expect(annotations[1][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[1][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[1][:name]).to eq "conjur/mime_type"
        expect(annotations[1][:value]).to eq "text/plain"
      end
    end
    context "When creating secret with annotations" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
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
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_annotations\",\"type\":\"static\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"test_ann\",\"value\":\"test\"}],\"permissions\":\"[]\"}")
        # Secret resource is created with annotations
        annotations = Annotation.where(resource_id:"rspec:variable:data/secrets/secret_annotations").all
        expect(annotations.size).to eq 3
        expect(annotations[2][:resource_id]).to eq "rspec:variable:data/secrets/secret_annotations"
        expect(annotations[2][:policy_id]).to eq "rspec:policy:data/secrets"
        expect(annotations[2][:name]).to eq "conjur/kind"
        expect(annotations[2][:value]).to eq "static"
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

  describe "Create static secret with permissions with input errors" do
    context "When creating secret with not valid privilege" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "read", "write"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00191E The value in the 'Resource rspec:user:alice privileges' parameter is not valid. Error: Allowed values are [read execute update]")
      end
    end
    context "When creating secret with not valid subject kind" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "subject": {
                    "kind": "users",
                    "id": "alice"
                  },
                  "privileges": [ "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00191E The value in the 'Resource alice kind' parameter is not valid. Error: Allowed values are [user host group]")
      end
    end
    context "When creating secret with not valid subject id" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
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
        post("/secrets",
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
    context "When creating secret with no subject" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "privileges": [ "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: Privilege Subject")
      end
    end
    context "When creating secret with no subject id" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "subject": {
                    "kind": "user"
                  },
                  "privileges": [ "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: id")
      end
    end
    context "When creating secret with no subject kind" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "subject": {
                    "id": "alice"
                  },
                  "privileges": [ "read"]
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: kind")
      end
      end
    context "When creating secret with no privileges" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret_annotations",
              "type": "static",
               "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  }
                }          
              ]       
          }
        BODY
      end
      it 'Failed on input validation' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        # correct response body
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: Privileges")
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
              "type": "static",
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
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_user_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"read\",\"update\"]}],\"annotations\":\"[]\"}")
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
              "type": "static",
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
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_workload_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"host\",\"id\":\"/data/host1\"},\"privileges\":[\"execute\",\"read\"]}],\"annotations\":\"[]\"}")
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
              "type": "static",
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
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_group_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"group\",\"id\":\"/data/group1\"},\"privileges\":[\"execute\",\"update\"]}],\"annotations\":\"[]\"}")
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
              "type": "static",
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
        post("/secrets",
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_permissions\",\"type\":\"static\",\"permissions\":[{\"subject\":{\"kind\":\"group\",\"id\":\"/data/group1\"},\"privileges\":[\"execute\"]},{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"update\"]}],\"annotations\":\"[]\"}")
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

  describe "Create ephemeral secret input validations" do
    context "when creating secret with no ephemeral value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral"
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: ephemeral")
      end
    end
    context "when creating secret with no issuer field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: issuer")
      end
    end
    context "when creating secret with no issuer field empty" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "",
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: issuer")
      end
    end
    context "when creating secret with no issuer field wrong type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": 4,
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'issuer' parameter must be of 'type=String'")
      end
    end
    context "when creating secret with no ttl field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: ttl")
      end
    end
    context "when creating secret with ttl wrong field type" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": "1200",
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'ttl' parameter must be of 'type=Numeric'")
      end
    end
    context "when creating secret with no type field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: type")
      end
    end
    context "when creating secret with empty type field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": ""
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00190E Missing required parameter: type")
      end
    end
    context "when creating secret with invalid type field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": "gcp"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00191E The value in the 'Ephemeral type' parameter is not valid. Error: Allowed values are [aws]")
      end
    end
    context "when creating secret with wrong type for type field" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": 5
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("CONJ00192E The 'type' parameter must be of 'type=String'")
      end
    end
    context "when creating ephemeral secret with value" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "value": "password",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("Adding value to an ephemeral secret is not allowed")
      end
    end
    context "when creating ephemeral secret not under correct branch" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Ephemeral secret can be created only under data/ephemerals/")
      end
    end
    context "when creating ephemeral secret with no existent issuer" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "issuer1",
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      it 'Secret creation failed on 404' do
        post("/secrets",
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
        expect(parsed_body["error"]["message"]).to eq("Issuer 'issuer1' not found in account 'rspec'")
      end
    end
    context "when creating ephemeral secret with ttl bigger then issuer ttl" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/ephemerals",
              "name": "ephemeral_secret",
              "type": "ephemeral",
              "ephemeral": {
                "issuer": "aws-issuer-1",
                "ttl": 1200,
                "type": "aws"
              } 
          }
        BODY
      end
      let(:payload_create_issuers) do
          <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 1000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        #Create issuer
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        post("/secrets",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Ephemeral secret ttl can't be bigger then the issuer ttl 1000")
      end
    end
  end

end
