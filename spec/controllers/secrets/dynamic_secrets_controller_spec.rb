require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe DynamicSecretsController, type: :request do
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
        - !policy dynamic
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

  describe "Create ephemeral secret input validations" do
    context "when creating ephemeral secret with no existent issuer" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "ephemeral_secret",
              "issuer": "issuer1",
              "ttl": 1200,
              "method": "federation-token"
          }
        BODY
      end
      it 'Secret creation failed on 404' do
        post("/secrets/dynamic",
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
              "branch": "/data/dynamic",
              "name": "ephemeral_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
              "method": "federation-token"
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

        post("/secrets/dynamic",
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
        expect(parsed_body["error"]["message"]).to eq("Dynamic secret ttl can't be bigger than the issuer ttl 1000")
      end
    end
    context "when creating ephemeral secret with no method" do
      let(:payload_create_secret) do
        <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "ephemeral_secret",
              "issuer": "issuer1",
              "ttl": 1200
          }
        BODY
      end
      it 'Secret creation failed on 400' do
        post("/secrets/dynamic",
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
        expect(parsed_body["error"]["message"]).to eq("Dynamic Secret method is unsupported")
      end
    end
  end

  describe "Create ephemeral permissions validations" do
    let(:payload_create_secret) do
      <<~BODY
        {
            "branch": "/data/dynamic",
            "name": "ephemeral_secret",
            "issuer": "aws-issuer-1",
            "ttl": 1200,
            "method": "federation-token"           
        }
      BODY
    end
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 2000,
          "type": "aws",
          "data": {
            "access_key_id": "my-key-id",
            "secret_access_key": "my-key-secret"
          }
        }
      BODY
    end
    before do
      #Create issuer
      post("/issuers/rspec",
           env: token_auth_header(role: admin_user).merge(
             'RAW_POST_DATA' => payload_create_issuers,
             'CONTENT_TYPE' => "application/json"
           ))
      assert_response :created
    end
    context "when creating ephemeral secret with no use permissions on issuer policy" do
      let(:permit_policy) do
        <<~POLICY
          - !permit
            resource: !policy data/dynamic
            privilege: [ update ]
            role: !user /alice
        POLICY
      end
      it 'Secret creation failed on 403' do
        patch(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => permit_policy }
          )
        )
        assert_response :success

        post("/secrets/dynamic",
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
    context "when creating ephemeral secret with no update permissions on secret policy" do
      let(:permit_policy) do
        <<~POLICY
          - !permit
            resource: !policy conjur/issuers/aws-issuer-1
            privilege: [ use ]
            role: !user /alice
        POLICY
      end
      it 'Secret creation failed on 403' do
        patch(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => permit_policy }
          )
        )
        assert_response :success

        post("/secrets/dynamic",
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
    context "when creating ephemeral secret with all permissions" do
      let(:permit_policy) do
        <<~POLICY
          - !permit
            resource: !policy conjur/issuers/aws-issuer-1
            privilege: [ use ]
            role: !user /alice

          - !permit
            resource: !policy data/dynamic
            privilege: [ update ]
            role: !user /alice
        POLICY
      end
      it 'Secret creation succeeds' do
        patch(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => permit_policy }
          )
        )
        assert_response :success

        post("/secrets/dynamic",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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

  describe "Ephemeral secret creation" do
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 2000,
          "type": "aws",
          "data": {
            "access_key_id": "my-key-id",
            "secret_access_key": "my-key-secret"
          }
        }
      BODY
    end
    let(:permit_policy) do
      <<~POLICY
          - !permit
            resource: !policy conjur/issuers/aws-issuer-1
            privilege: [ use ]
            role: !user /alice

          - !permit
            resource: !policy data/dynamic
            privilege: [ update ]
            role: !user /alice
        POLICY
    end
    before do
      #Create issuer
      post("/issuers/rspec",
           env: token_auth_header(role: admin_user).merge(
             'RAW_POST_DATA' => payload_create_issuers,
             'CONTENT_TYPE' => "application/json"
           ))
      assert_response :created

      patch(
        '/policies/rspec/policy/root',
        env: token_auth_header(role: admin_user).merge(
          { 'RAW_POST_DATA' => permit_policy }
        )
      )
      assert_response :success
    end
    context "when creating assume role ephemeral secret" do
      let(:payload_create_ephemeral_secret) do
        <<~BODY
        {
            "branch": "/data/dynamic",
            "name": "ephemeral_secret",
            "type": "ephemeral",
            "annotations": [
              {
                "name": "description",
                "value": "desc"
              }
            ],
            "permissions": [
              {
                "subject": {
                  "kind": "user",
                  "id": "alice"
                },
                "privileges": [ "read" ]
              }  
            ], 
            "issuer": "aws-issuer-1",
            "ttl": 1200,
            "method": "assume-role",
            "method_params": {
                "region": "us-east-1",
                "inline_policy": "{}",
                "role_arn": "role"      
            } 
        }
      BODY
      end
      it 'Secret resource was created' do
        post("/secrets/dynamic",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_ephemeral_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        expect(response.body).to eq('{"name":"ephemeral_secret","branch":"/data/dynamic"}')
        #expect(response.body).to eq("{\"branch\":\"/data/dynamic\",\"name\":\"ephemeral_secret\",\"type\":\"ephemeral\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"read\"]}],\"ephemeral\":{\"issuer\":\"aws-issuer-1\",\"ttl\":1200,\"type\":\"aws\",\"type_params\":{\"method\":\"assume-role\",\"region\":\"us-east-1\",\"inline_policy\":\"{}\",\"method_params\":{\"role_arn\":\"role\"}}}}")
        # Secret resource is created
        resource = Resource["rspec:variable:data/dynamic/ephemeral_secret"]
        expect(resource).to_not be_nil
        # user with permissions can see the secret
        get("/resources/rspec?kind=variable&search=data/dynamic/ephemeral_secret",
            env: token_auth_header(role: alice_user)
        )
        assert_response :success
        # Check the variable resource is with all the information (as the object also contains created at we want to check without it so partial json)
        parsed_body = JSON.parse(response.body)
        #expect(parsed_body[0].to_s.include?('"id"=>"rspec:variable:data/dynamic/ephemeral_secret", "owner"=>"rspec:policy:data/dynamic", "policy"=>"rspec:policy:data/dynamic", "permissions"=>[{"privilege"=>"read", "role"=>"rspec:user:alice", "policy"=>"rspec:policy:data/dynamic"}], "annotations"=>[{"name"=>"dynamic/issuer", "value"=>"aws-issuer-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/ttl", "value"=>"1200", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/method", "value"=>"assume-role", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/role-arn", "value"=>"role", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/region", "value"=>"us-east-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/inline-policy", "value"=>"{}", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"description", "value"=>"desc", "policy"=>"rspec:policy:data/dynamic"}], "secrets"=>[]}')).to eq(true)
        # Correct audit is returned
        #audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        #verify_audit_message(audit_message)
      end
    end
    context "when creating federation token ephemeral secret" do
      let(:payload_create_ephemeral_secret) do
        <<~BODY
        {
            "branch": "/data/dynamic",
            "name": "ephemeral_secret",
            "annotations": [
              {
                "name": "description",
                "value": "desc"
              }
            ],
            "permissions": [
              {
                "subject": {
                  "kind": "user",
                  "id": "alice"
                },
                "privileges": [ "read" ]
              }  
            ], 
            "issuer": "aws-issuer-1",
            "ttl": 1200,
            "method": "federation-token",
            "method_params": {
              "region": "us-east-1",
              "inline_policy": "{}"              
            } 
        }
      BODY
      end
      it 'Secret resource was created' do
        post("/secrets/dynamic",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_ephemeral_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        #expect(response.body).to eq("{\"branch\":\"/data/dynamic\",\"name\":\"ephemeral_secret\",\"type\":\"ephemeral\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"read\"]}],\"ephemeral\":{\"issuer\":\"aws-issuer-1\",\"ttl\":1200,\"type\":\"aws\",\"type_params\":{\"method\":\"federation-token\",\"region\":\"us-east-1\",\"inline_policy\":\"{}\"}}}")
        # Secret resource is created
        resource = Resource["rspec:variable:data/dynamic/ephemeral_secret"]
        expect(resource).to_not be_nil
        # user with permissions can see the secret
        get("/resources/rspec?kind=variable&search=data/dynamic/ephemeral_secret",
            env: token_auth_header(role: alice_user)
        )
        assert_response :success
        # Check the variable resource is with all the information (as the object also contains created at we want to check without it so partial json)
        parsed_body = JSON.parse(response.body)
             expect(parsed_body[0].to_s.include?('"id"=>"rspec:variable:data/dynamic/ephemeral_secret", "owner"=>"rspec:policy:data/dynamic", "policy"=>"rspec:policy:data/dynamic", "permissions"=>[{"privilege"=>"read", "role"=>"rspec:user:alice", "policy"=>"rspec:policy:data/dynamic"}], "annotations"=>[{"name"=>"dynamic/issuer", "value"=>"aws-issuer-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/ttl", "value"=>"1200", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/method", "value"=>"federation-token", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/region", "value"=>"us-east-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/inline-policy", "value"=>"{}", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"description", "value"=>"desc", "policy"=>"rspec:policy:data/dynamic"}], "secrets"=>[]}')).to eq(true)
        # Correct audit is returned
        #audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        #verify_audit_message(audit_message)
      end
    end
  end

end
