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

  describe "Dynamic secret creation - Input validations" do
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

  describe "Dynamic secret creation - Permissions validations" do
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

  describe "Dynamic secret creation" do
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
        expect(response.body).to eq('{"branch":"/data/dynamic","name":"ephemeral_secret"}')
        #expect(response.body).to eq("{\"branch\":\"/data/ephemerals\",\"name\":\"ephemeral_secret\",\"type\":\"ephemeral\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[{\"subject\":{\"kind\":\"user\",\"id\":\"alice\"},\"privileges\":[\"read\"]}],\"ephemeral\":{\"issuer\":\"aws-issuer-1\",\"ttl\":1200,\"type\":\"aws\",\"type_params\":{\"method\":\"assume-role\",\"region\":\"us-east-1\",\"inline_policy\":\"{}\",\"method_params\":{\"role_arn\":\"role\"}}}}")
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
        # expect(parsed_body[0].to_s.include?('"id"=>"rspec:variable:data/dynamic/ephemeral_secret", "owner"=>"rspec:policy:data/dynamic", "policy"=>"rspec:policy:data/dynamic", "permissions"=>[{"privilege"=>"read", "role"=>"rspec:user:alice", "policy"=>"rspec:policy:data/dynamic"}], "annotations"=>[{"name"=>"dynamic/issuer", "value"=>"aws-issuer-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/ttl", "value"=>"1200", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/method", "value"=>"federation-token", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/region", "value"=>"us-east-1", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"dynamic/inline-policy", "value"=>"{}", "policy"=>"rspec:policy:data/dynamic"}, {"name"=>"description", "value"=>"desc", "policy"=>"rspec:policy:data/dynamic"}], "secrets"=>[]}')).to eq(true)
        # Correct audit is returned
        #audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        #verify_audit_message(audit_message)
      end
    end
  end

  describe "Dynamic Secret Replace" do
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
    let(:payload_create_secret) do
      <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "secret_to_update",
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
              {
                "name": "description",
                "value": "desc"
              },
              {
                "name": "annotation_to_delete",
                "value": "delete"
              }
              ],
              "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "update" ]
                }  
              ]
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

      # Create secret
      post("/secrets/dynamic",
          env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
            {
              'RAW_POST_DATA' => payload_create_secret,
              'CONTENT_TYPE' => "application/json"
            }
          )
      )
      # Correct response code
      assert_response :created
    end
    describe "Dynamic secret Replace - Input validations" do
      context "Trying to Replace secret with url input validations" do
        let(:payload_update_secret) do
          <<~BODY
            {
               "issuer": "aws-issuer-1",
                "ttl": 1200,
                "method": "federation-token"
            }
          BODY
        end
        it 'Secret not exist' do
          put("/secrets/dynamic/data/dynamic/secret_not_exists",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Variable 'data/dynamic/secret_not_exists' not found in account 'rspec'")
        end
        it 'Branch not exist' do
          put("/secrets/dynamic/data/no_secrets/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Variable 'data/no_secrets/secret_to_update' not found in account 'rspec'")
        end
        it 'Empty Branch' do
          put("/secrets/dynamic//secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Variable 'secret_to_update' not found in account 'rspec'")
        end
      end
      context "Trying to Replace secret with branch in body" do
        let(:payload_update_secret) do
          <<~BODY
            {
                "branch": "data/dynamic"   ,
                "issuer": "aws-issuer-1",
                "ttl": 100,
                "method": "federation-token"           
            }
          BODY
        end
        it 'Fails on unprocessable entity' do
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :unprocessable_entity
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Branch is not allowed in the request body")
        end
      end
      context "Trying to Replace secret with secret name in body" do
        let(:payload_update_secret) do
          <<~BODY
            {
                "name": "secrets2",
                "issuer": "aws-issuer-1",
                "ttl": 100,
                "method": "federation-token"       
            }
          BODY
        end
        it 'Fails on unprocessable entity' do
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :unprocessable_entity
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Secret name is not allowed in the request body")
        end
      end
      context "when replacing dynamic secret with no existent issuer" do
        let(:payload_update_secret) do
          <<~BODY
            {
                "issuer": "issuer2",
                "ttl": 1200,
                "method": "federation-token"
            }
          BODY
        end
        it 'Secret replace failed on 404' do
          put("/secrets/dynamic/data/dynamic/secret_to_update",
               env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                 {
                   'RAW_POST_DATA' => payload_update_secret,
                   'CONTENT_TYPE' => "application/json"
                 }
               )
          )
          # Correct response code
          assert_response :not_found
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Issuer 'issuer2' not found in account 'rspec'")
        end
      end
      context "when replacing dynamic secret with ttl bigger then issuer ttl" do
        let(:payload_update_secret) do
          <<~BODY
            {
               "issuer": "aws-issuer-1",
                "ttl": 1200,
                "method": "federation-token"
            }
          BODY
        end
        it 'Secret replace failed on 400' do
          put("/secrets/dynamic/data/dynamic/secret_to_update",
               env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                 {
                   'RAW_POST_DATA' => payload_update_secret,
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
      context "when replacing dynamic secret with no method" do
      let(:payload_update_secret) do
        <<~BODY
          {
              "issuer": "issuer1",
              "ttl": 1200
          }
        BODY
      end
      it 'Secret replace failed on 400' do
        put("/secrets/dynamic/data/dynamic/ephemeral_secret",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_update_secret,
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

    describe "Dynamic Secret Replace - Permissions" do
      let(:payload_update_secret) do
        <<~BODY
            {
                "issuer": "aws-issuer-1",
                "ttl": 100,
                "method": "federation-token"       
            }
          BODY
      end
      context "Trying to update secret without update permissions on the policy" do
        let(:permit_policy) do
          <<~POLICY
          - !permit
            resource: !policy data/dynamic
            privilege: [ create ]
            role: !user /alice
        POLICY
        end
        it 'permissions check fails' do
          patch(
            '/policies/rspec/policy/root',
            env: token_auth_header(role: admin_user).merge(
              { 'RAW_POST_DATA' => permit_policy }
            )
          )
          assert_response :success

          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :forbidden
        end
      end
      context "Trying to update secret without use permissions on the issuer" do
        let(:permit_policy) do
          <<~POLICY
          - !permit
            resource: !policy data/dynamic
            privilege: [ update ]
            role: !user /alice
        POLICY
        end
        it 'permissions check fails' do
          patch(
            '/policies/rspec/policy/root',
            env: token_auth_header(role: admin_user).merge(
              { 'RAW_POST_DATA' => permit_policy }
            )
          )
          assert_response :success

          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :forbidden
        end
      end
    end

    describe "Dynamic Secret Replace" do
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
      let(:payload_create_issuer2) do
        <<~BODY
        {
          "id": "aws-issuer-2",
          "max_ttl": 100,
          "type": "aws",
          "data": {
            "access_key_id": "my-key-id",
            "secret_access_key": "my-key-secret"
          }
        }
      BODY
      end
      before do
        patch(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => permit_policy }
          )
        )
        assert_response :success

        #Create issuer
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer2,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
      end
      context "Update secret annotations" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc2"
                },
                {
                  "name": "annotation_to_add",
                  "value": "add"
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
              ]
          }
        BODY
        end
        it 'annotations are updated' do
          # check annotations before update
          annotations = Annotation.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(annotations.find { |hash| hash[:name] == 'description' }[:value]).to eq "desc"
          expect(annotations.find { |hash| hash[:name] == 'annotation_to_delete' }[:value]).to eq "delete"
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check annotations were updated
          annotations = Annotation.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(annotations.find { |hash| hash[:name] == 'description' }[:value]).to eq "desc2"
          expect(annotations.find { |hash| hash[:name] == 'annotation_to_add' }[:value]).to eq "add"
          expect(annotations.find { |hash| hash[:name] == "annotation_to_delete" }).to eq nil
        end
      end
      context "Remove secret annotations" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "mime_type": "plain",
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "read" ]
                }  
              ]
          }
        BODY
        end
        it 'annotations are updated' do
          # Call update secret
          put("/secrets/static/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check annotations were updated
          annotations = Annotation.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(annotations.find { |hash| hash[:name] == 'description' }).to eq nil
          expect(annotations.find { |hash| hash[:name] == "annotation_to_delete" }).to eq nil
        end
      end
      context "Update secret annotations with wrong object" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description"
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
              ]
          }
        BODY
        end
        it 'annotations were not updated' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check annotations were not updated
          annotations = Annotation.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(annotations.size).to eq 4
        end
      end
      context "Update secret permissions" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "annotation_to_delete",
                  "value": "delete"
                }
              ],
              "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "read" ]
                } ,
                {
                  "subject": {
                    "kind": "host",
                    "id": "data/host1"
                  },
                  "privileges": [ "execute" ]
                } 
              ]
          }
        BODY
        end
        it 'permissions are updated' do
          # check permissions before update
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 1
          expect(permissions[0][:role_id]).to eq "rspec:user:alice"
          expect(permissions[0][:privilege]).to eq "update"
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check permissions were updated
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 2
          expect(permissions[0][:role_id]).to eq "rspec:user:alice"
          expect(permissions[0][:privilege]).to eq "read"
          expect(permissions[1][:role_id]).to eq "rspec:host:data/host1"
          expect(permissions[1][:privilege]).to eq "execute"
        end
      end
      context "Remove secret permissions" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "annotation_to_delete",
                  "value": "delete"
                }
              ]
          }
        BODY
        end
        it 'permissions are updated' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check permissions were updated
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 0
        end
      end
      context "Update secret permissions with not existing host" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "annotation_to_delete",
                  "value": "delete"
                }
              ],
              "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "alice"
                  },
                  "privileges": [ "read" ]
                } ,
                {
                  "subject": {
                    "kind": "host",
                    "id": "data/host2"
                  },
                  "privileges": [ "execute" ]
                } 
              ]
          }
        BODY
        end
        it 'permissions were not updated' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          # correct response body
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Host 'data/host2' not found in account 'rspec'")
          # Check permissions were not updated
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 1
        end
      end
      context "Update secret permissions with not existing user" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "annotation_to_delete",
                  "value": "delete"
                }
              ],
              "permissions": [
                {
                  "subject": {
                    "kind": "user",
                    "id": "luba"
                  },
                  "privileges": [ "read" ]
                }
              ]
          }
        BODY
        end
        it 'permissions were not updated' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          # correct response body
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("User 'luba' not found in account 'rspec'")
          # Check permissions were not updated
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 1
        end
      end
      context "Update secret permissions with not existing group" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "federation-token",
              "annotations": [
                {
                  "name": "description",
                  "value": "desc"
                },
                {
                  "name": "annotation_to_delete",
                  "value": "delete"
                }
              ],
              "permissions": [
                {
                  "subject": {
                    "kind": "group",
                    "id": "luba_group"
                  },
                  "privileges": [ "read" ]
                }
              ]
          }
        BODY
        end
        it 'permissions were not updated' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :not_found
          # correct response body
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Group 'luba_group' not found in account 'rspec'")
          # Check permissions were not updated
          permissions = Permission.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(permissions.size).to eq 1
        end
      end
      context "Update secret method" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 120,
              "method": "assume-role",
              "method": "assume-role",
              "method_params": {
                  "role_arn": "role"      
              }, 
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
                  "privileges": [ "update" ]
                }  
              ]
          }
        BODY
        end
        it 'secret method was changed' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :ok
          # Check the body to see type was changed
          # TODO
        end
      end
      context "Update secret issuer" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-2",
              "ttl": 120,
              "method": "federation-token",
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
                  "privileges": [ "update" ]
                }  
              ]
          }
        BODY
        end
        it 'Update failed on validation with new issuer' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
                  'CONTENT_TYPE' => "application/json"
                }
              )
          )
          # Correct response code
          assert_response :bad_request
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Dynamic secret ttl can't be bigger than the issuer ttl 100")
        end
      end
      context "Update secret ttl" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 1200,
              "method": "federation-token",
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
                  "privileges": [ "update" ]
                }  
              ]
          }
        BODY
        end
        it 'Update failed on validation with issuer' do
          # Call update secret
          put("/secrets/dynamic/data/dynamic/secret_to_update",
              env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
                {
                  'RAW_POST_DATA' => payload_update_secret,
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
    end

    #describe "Dynamic Secret CRUD" do
  end


end
