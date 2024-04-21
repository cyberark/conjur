# frozen_string_literal: true

require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

VALID_AWS_KEY = '"AKIAIOSFODNN7EXAMPLE"'
VALID_AWS_SECRET = '"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"'

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
        # Correct audit is returned
        audit_message = 'rspec:user:admin failed to create secret /data/dynamic/ephemeral_secret with url: \'/secrets/dynamic\' and content: {"branch":"/data/dynamic","name":"ephemeral_secret","issuer":"issuer1","ttl":1200,"method":"federation-token"}: Issuer \'issuer1\' not found in account \'rspec\''
        verify_audit_message(audit_message)
      end
    end
    context "when creating dynamic secret with ttl bigger then issuer ttl" do
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
              "access_key_id": #{VALID_AWS_KEY},
              "secret_access_key":#{VALID_AWS_SECRET}
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
        assert_response :unprocessable_entity
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("The TTL of the dynamic secret can't exceed the maximum TTL defined in the issuer.")
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
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
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
          "max_ttl": 1400,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
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
                "role_arn": "arn:aws:iam::123456789012:role/my-role-name"      
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
        validate_response("ephemeral_secret", "/data/dynamic", "aws-issuer-1", 1200, "assume-role",
                          {"role_arn"=>"arn:aws:iam::123456789012:role/my-role-name","region"=>"us-east-1","inline_policy"=>"{}"},
                          [{"name"=>"description", "value"=>"desc"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # Secret resource is created
        resource = Resource["rspec:variable:data/dynamic/ephemeral_secret"]
        expect(resource).to_not be_nil
        # user with permissions can see the secret
        get("/resources/rspec?kind=variable&search=data/dynamic/ephemeral_secret",
            env: token_auth_header(role: alice_user)
        )
        assert_response :success
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
        validate_response("ephemeral_secret", "/data/dynamic", "aws-issuer-1", 1200, "federation-token",
                          {"region"=>"us-east-1","inline_policy"=>"{}"},
                          [{"name"=>"description", "value"=>"desc"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # Secret resource is created
        resource = Resource["rspec:variable:data/dynamic/ephemeral_secret"]
        expect(resource).to_not be_nil
        # user with permissions can see the secret
        get("/resources/rspec?kind=variable&search=data/dynamic/ephemeral_secret",
            env: token_auth_header(role: alice_user)
        )
        assert_response :success
      end
    end
  end

  describe "Dynamic Secret Replace" do
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 1400,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
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
              "ttl": 1200,
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
                "ttl": 1000,
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
                "ttl": 1000,
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
                "ttl": 3000,
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
          assert_response :unprocessable_entity
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("The TTL of the dynamic secret can't exceed the maximum TTL defined in the issuer.")
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
                "ttl": 1000,
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
          "max_ttl": 1200,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
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
              "ttl": 1200,
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
              "mime_type": "plain/text",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
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
          expect(annotations.find { |hash| hash[:name] == 'description' }).to eq nil
          expect(annotations.find { |hash| hash[:name] == "annotation_to_delete" }).to eq nil
        end
      end
      context "Update secret annotations with wrong object" do
        let(:payload_update_secret) do
          <<~BODY
          {
              "issuer": "aws-issuer-1",
              "ttl": 1200,
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
          assert_response :bad_request
          # Check annotations were not updated
          annotations = Annotation.where(resource_id:"rspec:variable:data/dynamic/secret_to_update").all
          expect(annotations.size).to eq 5
        end
      end
      context "Update secret permissions" do
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
              "ttl": 1200,
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
              "ttl": 1200,
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
              "ttl": 1200,
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
              "ttl": 1200,
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
              "ttl": 1200,
              "method": "assume-role",
              "method": "assume-role",
              "method_params": {
                  "role_arn": "arn:aws:iam::123456789012:role/my-role-name"      
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
              "ttl": 3000,
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
          assert_response :unprocessable_entity
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("The TTL of the dynamic secret can't exceed the maximum TTL defined in the issuer.")
        end
      end
      context "Update secret ttl" do
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
          assert_response :unprocessable_entity
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["error"]["message"]).to eq("Dynamic variable TTL is out of range for federation token (range is 900 to 43200)")
        end
      end
    end

    #describe "Dynamic Secret CRUD" do
  end

  describe 'Get existing dynamic secret' do
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 1400,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
          }
        }
      BODY
    end
    let(:payload_create_federation_secret) do
      <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
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
                }  
              ]
           }
        BODY
    end
    let(:payload_create_role_secret) do
      <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "assume_role_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
              "method": "assume-role",
              "method_params": {
                "role_arn": "arn:aws:iam::123456789012:role/my-role-name"
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
                  "privileges": [ "read" ]
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
               'RAW_POST_DATA' => payload_create_federation_secret,
               'CONTENT_TYPE' => "application/json"
             }
           )
      )
      # Correct response code
      assert_response :created
      post("/secrets/dynamic",
           env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
             {
               'RAW_POST_DATA' => payload_create_role_secret,
               'CONTENT_TYPE' => "application/json"
             }
           )
      )
      # Correct response code
      assert_response :created
    end
    # Full flow with using both policy and apis
    context 'User with read permissions calls for get federation token secret' do
      it 'returns correct json body' do
        get('/secrets/dynamic/data/dynamic/federation_token_secret',
          env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :success
        validate_response("federation_token_secret", "/data/dynamic", "aws-issuer-1", 1200, "federation-token",
                          nil,
                          [{"name"=>"description", "value"=>"desc"}, { "name" => "annotation_to_delete", "value" => "delete" }],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
      end
    end
    context 'User with read permissions calls for get assume role secret' do
      it 'returns correct json body' do
        get('/secrets/dynamic/data/dynamic/assume_role_secret',
            env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :success
        validate_response("assume_role_secret", "/data/dynamic", "aws-issuer-1", 1200, "assume-role",
                          {"role_arn"=>"arn:aws:iam::123456789012:role/my-role-name"},
                          [{"name"=>"description", "value"=>"desc"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
      end
    end
    context 'User with no read permissions calls for get assume role secret' do
      it 'returns 403' do
        get('/secrets/dynamic/data/dynamic/assume_role_secret',
            env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :forbidden
      end
    end
    context 'Get not existent secret' do
      it 'returns 404' do
        get('/secrets/dynamic/data/dynamic/secret_not_found',
            env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :not_found
      end
    end
    context 'Get from not existent branch' do
      it 'returns 404' do
        get('/secrets/dynamic/data/dynamics/assume_role_secret',
            env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :not_found
      end
    end
    context 'Get with empty branch' do
      it 'returns 404' do
        get('/secrets/dynamic//assume_role_secret',
            env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :not_found
      end
    end
    context 'Get with no branch' do
      it 'returns 404' do
        get('/secrets/dynamic/assume_role_secret',
            env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
              'CONTENT_TYPE' => "application/json"
            )
        )
        assert_response :not_found
      end
    end
  end

  describe 'Call dynamic secret apis for static secret' do
    let(:permit_policy) do
      <<~POLICY
        - !permit
          resource: !policy data/secrets
          privilege: [ update ]
          role: !user /alice
      POLICY
    end
    let(:payload_update_secret) do
      <<~BODY
          {
            "mime_type": "plain/text",
            "value": "password2",
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
                "privileges": [ "update", "read", "execute" ]
              }  
            ]
        }
        BODY
    end
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 1400,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
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
             'RAW_POST_DATA' => payload_create_issuers,
             'CONTENT_TYPE' => "application/json"
           ))
      assert_response :created
    end
    context 'create static secret under dynamic branch with static api' do
      let(:payload_create_secret) do
        <<~BODY
        {
            "branch": "/data/dynamic",
            "name": "secret_to_update",
            "mime_type": "plain/text",
            "value": "password",
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
                "privileges": [ "update", "read", "execute" ]
              }  
            ]
        }
      BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("The data/dynamic/ branch is reserved for dynamic secrets only. Choose a different branch under /data for your static secret.")
      end
    end
    context 'create static secret under dynamic branch with dynamic api' do
      let(:payload_create_secret) do
        <<~BODY
        {
            "branch": "/data/dynamic",
            "name": "secret_to_update",
            "mime_type": "plain/text",
            "value": "password",
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
                "privileges": [ "update", "read", "execute" ]
              }  
            ]
        }
      BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/dynamic",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Dynamic Secret method is unsupported")
      end
    end
    context 'create dynamic secret under dynamic branch with static api' do
      let(:payload_create_federation_secret) do
        <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1000,
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
                }  
              ]
           }
        BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_federation_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("The data/dynamic/ branch is reserved for dynamic secrets only. Choose a different branch under /data for your static secret.")
      end
    end
    context 'create dynamic secret under regular branch with static api' do
      let(:payload_create_federation_secret) do
        <<~BODY
          {
              "branch": "/data/secrets",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1000,
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
                }  
              ]
           }
        BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/static",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_federation_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("A static secret can't contain an 'issuer' field")
      end
    end
    context 'update static secret under regular branch with dynamic api' do
      let(:payload_create_secret) do
        <<~BODY
        {
            "branch": "/data/secrets",
            "name": "secret_to_update",
            "mime_type": "plain/text",
            "value": "password",
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
                "privileges": [ "update", "read", "execute" ]
              }  
            ]
        }
      BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/static/",
            env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
              {
                'RAW_POST_DATA' => payload_create_secret,
                'CONTENT_TYPE' => "application/json"
              }
            )
        )
        assert_response :success
        put("/secrets/dynamic/data/secrets/secret_to_update",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_update_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Dynamic Secret method is unsupported")
      end
    end
    context 'update dynamic secret under dynamic branch with static api' do
      let(:payload_create_federation_secret) do
        <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1000,
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
                }  
              ]
           }
        BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/dynamic/",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_federation_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :success
        put("/secrets/static/data/dynamic/federation_token_secret",
            env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
              {
                'RAW_POST_DATA' => payload_update_secret,
                'CONTENT_TYPE' => "application/json"
              }
            )
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("The data/dynamic/ branch is reserved for dynamic secrets only. Choose a different branch under /data for your static secret.")
      end
    end
    context 'get static secret under regular branch with dynamic api' do
      let(:payload_create_secret) do
        <<~BODY
        {
            "branch": "/data/secrets",
            "name": "secret_to_update",
            "mime_type": "plain/text",
            "value": "password",
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
                "privileges": [ "update", "read", "execute" ]
              }  
            ]
        }
      BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/static/",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :success
        get("/secrets/dynamic/data/secrets/secret_to_update",
            env: token_auth_header(role: admin_user).merge(v2_api_header)
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("Dynamic Secret method is unsupported")
      end
    end
    context 'get dynamic secret under dynamic branch with static api' do
      let(:payload_create_federation_secret) do
        <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
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
                }  
              ]
           }
        BODY
      end
      it 'Request fails on input validation' do
        post("/secrets/dynamic/",
             env: token_auth_header(role: admin_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_federation_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :success
        get("/secrets/static/data/dynamic/federation_token_secret",
            env: token_auth_header(role: admin_user).merge(v2_api_header)
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["message"]).to eq("The data/dynamic/ branch is reserved for dynamic secrets only. Choose a different branch under /data for your static secret.")
      end
    end
  end

  describe "Dynamic Secret CRUD" do
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
    let(:payload_create_issuers) do
      <<~BODY
        {
          "id": "aws-issuer-1",
          "max_ttl": 1300,
          "type": "aws",
          "data": {
            "access_key_id": #{VALID_AWS_KEY},
            "secret_access_key":#{VALID_AWS_SECRET}
          }
        }
      BODY
    end
    let(:payload_create_federation_secret) do
      <<~BODY
          {
              "branch": "/data/dynamic",
              "name": "federation_token_secret",
              "issuer": "aws-issuer-1",
              "ttl": 1200,
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
                }  
              ]
           }
        BODY
    end
    let(:payload_update_federation_secret_policy) do
      <<~POLICY
          - !variable 
            id: federation_token_secret
            annotations:
              description: desc
              dynamic/issuer: aws-issuer-1  
              dynamic/ttl: 1100
              dynamic/method: federation-token
              dynamic/region: us-east-1    

          - !permit
            resource: !variable federation_token_secret
            privilege: [ read ]
            role: !user /alice    
        POLICY
    end
    let(:payload_update_role_secret) do
      <<~BODY
          {             
              "issuer": "aws-issuer-1",
              "ttl": 1100,
              "method": "assume-role",
              "method_params": {
                "role_arn": "arn:aws:iam::123456789012:role/my-role-name"
              },
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
    let(:payload_create_role_secret_policy) do
      <<~POLICY
          - !variable 
            id: assume_role_secret
            annotations:
              description: desc
              dynamic/issuer: aws-issuer-1  
              dynamic/ttl: 1100
              dynamic/method: assume-role
              dynamic/role-arn: arn:aws:iam::123456789012:role/my-role-name
              dynamic/region: us-east-1    

          - !permit
            resource: !variable assume_role_secret
            privilege: [ read ]
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
    context "Running all CRUD Actions" do
      it 'All actions succeed' do
        # Create federation token secret using api
        post("/secrets/dynamic",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_create_federation_secret,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        validate_response("federation_token_secret", "/data/dynamic", "aws-issuer-1", 1200, "federation-token",
                          nil,
                          [{"name"=>"description", "value"=>"desc"}, {"name"=>"annotation_to_delete","value"=>"delete"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # Correct audit is returned
        audit_message = 'rspec:user:alice successfully created secret /data/dynamic/federation_token_secret with url: \'/secrets/dynamic\' and content: {"branch":"/data/dynamic","name":"federation_token_secret","issuer":"aws-issuer-1","ttl":1200,"method":"federation-token","annotations":[{"name":"description","value":"desc"},{"name":"annotation_to_delete","value":"delete"}],"permissions":[{"subject":{"kind":"user","id":"alice"},"privileges":["read"]}]}'
        verify_audit_message(audit_message)
        # get federation token secret
        get("/secrets/dynamic/data/dynamic/federation_token_secret",
            env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        assert_response :ok
        validate_response("federation_token_secret", "/data/dynamic", "aws-issuer-1", 1200, "federation-token",
                          nil,
                          [{"name"=>"description", "value"=>"desc"}, {"name"=>"annotation_to_delete","value"=>"delete"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # Correct audit is returned
        audit_message = "rspec:user:alice successfully retrieved secret data/dynamic/federation_token_secret with url: '/secrets/dynamic/data/dynamic/federation_token_secret'"
        verify_audit_message(audit_message)
        # create assume role secret using policy
        patch(
          '/policies/rspec/policy/data/dynamic',
          env: token_auth_header(role: alice_user).merge(
            { 'RAW_POST_DATA' => payload_create_role_secret_policy }
          )
        )
        assert_response :success
        # get assume role secret
        get("/secrets/dynamic/data/dynamic/assume_role_secret",
            env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        assert_response :ok
        validate_response("assume_role_secret", "/data/dynamic", "aws-issuer-1", 1100, "assume-role",
                          {"role_arn"=>"arn:aws:iam::123456789012:role/my-role-name","region"=>"us-east-1"},
                          [{"name"=>"description", "value"=>"desc"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # update assume role secret
        put("/secrets/dynamic/data/dynamic/assume_role_secret",
            env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
              {
                'RAW_POST_DATA' => payload_update_role_secret,
                'CONTENT_TYPE' => "application/json"
              }
            )
        )
        assert_response :ok
        validate_response("assume_role_secret", "/data/dynamic", "aws-issuer-1", 1100, "assume-role",
                          {"role_arn"=>"arn:aws:iam::123456789012:role/my-role-name"},
                          [],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # Correct audit is returned
        audit_message = 'rspec:user:alice successfully changed secret data/dynamic/assume_role_secret with url: \'/secrets/dynamic/data/dynamic/assume_role_secret\' and content: {"issuer":"aws-issuer-1","ttl":1100,"method":"assume-role","method_params":{"role_arn":"arn:aws:iam::123456789012:role/my-role-name"},"permissions":[{"subject":{"kind":"user","id":"alice"},"privileges":["read"]}]}'
        verify_audit_message(audit_message)
        # get secret
        get("/secrets/dynamic/data/dynamic/assume_role_secret",
            env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        assert_response :ok
        validate_response("assume_role_secret", "/data/dynamic", "aws-issuer-1", 1100, "assume-role",
                          {"role_arn"=>"arn:aws:iam::123456789012:role/my-role-name"},
                          [],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
        # update federation token secret using policy
        patch(
          '/policies/rspec/policy/data/dynamic',
          env: token_auth_header(role: alice_user).merge(
            { 'RAW_POST_DATA' => payload_update_federation_secret_policy }
          )
        )
        assert_response :success
        # get federation token secret
        get("/secrets/dynamic/data/dynamic/federation_token_secret",
            env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        assert_response :ok
        validate_response("federation_token_secret", "/data/dynamic", "aws-issuer-1", 1100, "federation-token",
                          {"region"=>"us-east-1"},
                          [{"name"=>"description", "value"=>"desc"}, {"name"=>"annotation_to_delete","value"=>"delete"}],
                          [{"subject"=>{"id"=>"alice","kind"=>"user"},"privileges"=>["read"]}])
      end
    end
  end

  def validate_response(name, branch, issuer, ttl, method, method_params, annotations, permissions)
    response_body = JSON.parse(response.body)
    expect(response_body['name']).to eq(name)
    expect(response_body['branch']).to eq(branch)
    expect(response_body['issuer']).to eq(issuer)
    expect(response_body['ttl']).to eq(ttl)
    expect(response_body['method']).to eq(method)
    expect(response_body['method_params']).to eq(method_params)
    expect(compare_json_arrays(response_body['annotations'], annotations)).to eq(true)
    expect(compare_json_arrays(response_body['permissions'], permissions)).to eq(true)
  end

  def compare_json_arrays(array1, array2)
    # Sort arrays based on a unique identifier or key
    sorted_array1 = array_to_sorted_json(array1)
    sorted_array2 = array_to_sorted_json(array2)

    # Compare sorted arrays
    sorted_array1 == sorted_array2
  end

  def array_to_sorted_json(array)
    # Convert array of hashes to array of sorted JSON strings
    array.map { |item| item.to_json }.sort
  end
end
