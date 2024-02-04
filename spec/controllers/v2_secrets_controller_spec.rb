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
        id: data
        body:
        - !policy secrets
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"type\":\"static\"}")
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

  describe "Create static secret with input errors" do
    context "when creating secret with unsupported symbols in its name" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "secret/not_valid ",
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
        expect(parsed_body["error"]["message"]).to eq("Invalid 'name' parameter. The character '/' is not allowed.")
      end
    end
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret1\",\"type\":\"static\"}")
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
        expect(response.body).to eq("{\"branch\":\"/data/secrets\",\"name\":\"secret_annotations\",\"type\":\"static\",\"mime_type\":\"text/plain\",\"annotations\":\"[]\"}")
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
  end
end

# Test policy don;t exist
# Test response with value that the value doesn;t exist
# Test type and mime_type in response