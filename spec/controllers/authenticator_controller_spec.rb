# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

# Integration test for the V2 authenticator API's
describe AuthenticatorController, type: :request do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before(:all) do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  # Allows API calls to be made as the admin user
  let(:admin_request_env) do
    token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
    { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
  end

  def enable_request(body, current_user, resource_id: 'jwt/test-jwt1')
    patch(
      "/authenticators/rspec/#{resource_id}",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => body,
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/json"
      )
    )
  end

  def create_body(id, owner)
    base_body = {
      "type": "jwt",
      "name": id,
      "enabled": false,
      "data": {
        "jwks_uri": "http://uri",
        "identity": {
          "token_app_property": "prop",
          "enforced_claims": %w[test 123],
          "claim_aliases": { "myclaim": "myvalue", "second": "two" }
        }
      },
      "annotations": {
        "test": "123"
      }
    }

    base_body["owner"] = owner unless owner.nil?
    base_body
  end

  def create_request(current_user, owner: nil, id: "test-jwt3")
    post(
      "/authenticators/rspec",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => create_body(id, owner).to_json,
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/json"
      )
    )
  end

  def retrieve_authenticators(url, current_user)
    get(url, env: token_auth_header(role: current_user).merge(
      'ACCEPT' => "application/x.secretsmgr.v2beta+json"
    ))
  end

  def delete_authenticator(type, service_id, current_user)
    delete(
      "/authenticators/rspec/#{type}/#{service_id}", env: token_auth_header(role: current_user).merge(
        'ACCEPT' => "application/x.secretsmgr.v2beta+json"
      )
    )
  end

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201")
  end

  let(:test_policy) do
    <<~POLICY
      - !policy
        id: conjur/authn-jwt

      - !policy
        id: conjur/authn-jwt/test-jwt1
        body:
        - !webservice
          annotations:
            test: 123
            other: secret

        - !variable jwks-uri
        - !group users
        - !permit
          role: !group users
          privilege: [ update, authenticate ]
          resource: !webservice

      - !policy
        id: conjur/authn-jwt/test-jwt2
        body:
        - !webservice
          annotations:
            test: 456
            environment: staging
        - !variable jwks-uri
        - !group users
        - !permit
          role: !group users
          privilege: [ update, authenticate ]
          resource: !webservice

      - !policy
        id: conjur/authn-oidc/keycloak
        body:
        - !webservice
          annotations:
            description: Authentication service for Keycloak, based on Open ID Connect.

        - !variable
          id: provider-uri

        - !group users

        - !permit
          role: !group users
          privilege: [ read, authenticate ]
          resource: !webservice

      - !user alice
      - !user bob
      - !user grant
      - !user tester
      - !user restricted_user

      - !grant
        role: !group conjur/authn-oidc/keycloak/users
        member: !user alice
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user alice
      - !grant
        role: !group conjur/authn-jwt/test-jwt2/users
        member: !user alice
      - !grant
        role: !group conjur/authn-oidc/keycloak/users
        member: !user tester
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user tester
      - !grant
        role: !group conjur/authn-jwt/test-jwt2/users
        member: !user tester
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user restricted_user

      - !permit
        role: !user alice
        privilege: [ read ]
        resource: !policy conjur/authn-jwt

      - !permit
        role: !user restricted_user
        privilege: [ read ]
        resource: !policy conjur/authn-jwt/test-jwt1

      - !permit
        role: !user tester
        privilege: [ create, read, update, delete, authenticate ]
        resource: !policy conjur/authn-jwt

      - !permit
        role: !user tester
        privilege: [ create, read, update, delete, authenticate ]
        resource: !policy conjur/authn-jwt/test-jwt1

      - !permit
        role: !user tester
        privilege: [ create, read, update, delete, authenticate ]
        resource: !policy conjur/authn-jwt/test-jwt2

      - !permit
        role: !user tester
        privilege: [ create, read, update, delete, authenticate ]
        resource: !policy conjur/authn-oidc/keycloak

      - !permit
        role: !user grant
        privilege: [ read, create ]
        resource: !policy conjur/authn-jwt

    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:tester') }

  describe '#find_authenticator' do
    before do
      allow(Audit).to receive(:logger).and_return(Audit::Log::RubyAdapter.new(logger))
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user has permissions' do
      context 'The authenticator does not exist in policy' do
        it "returns a 404" do
          retrieve_authenticators('/authenticators/rspec/jwt/foo', current_user)
          expect(response.code).to eq('404')
          expect(log_output.string).to include("conjur: rspec:user:tester failed to retrieve authn-jwt foo with URI path: '/authenticators/rspec/jwt/foo': Authenticator: foo not found in account 'rspec'\n")
        end
      end
      context 'the authenticator is loaded in policy' do
        it "returns the authenticator" do
          retrieve_authenticators('/authenticators/rspec/jwt/test-jwt1', current_user)
          expect(response.code).to eq('200')
          expect(log_output.string).to include("conjur: rspec:user:tester successfully retrieved authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1'\n")
        end
      end
      context 'When current user has read only permission' do
        let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
        it "returns the authenticator when there is visibility" do
          retrieve_authenticators('/authenticators/rspec/oidc/keycloak', current_user)
          expect(response.code).to eq('200')
          expect(log_output.string).to include("conjur: rspec:user:alice successfully retrieved authn-oidc keycloak with URI path: '/authenticators/rspec/oidc/keycloak'\n")
        end
      end
    end
    context 'There is an unhandled error' do
      before do
        allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:find).and_raise("test error")
      end
      it 'creates an audit log for that error' do
        retrieve_authenticators('/authenticators/rspec/jwt/test-jwt1', current_user)
        expect(response.code).to eq('500')
        expect(log_output.string).to include("conjur: rspec:user:tester failed to retrieve authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1': test error\n")
      end
    end
  end

  describe '#list_authenticators' do
    before do
      allow(Audit).to receive(:logger).and_return(Audit::Log::RubyAdapter.new(logger))
    end
    context 'when user has permissions' do
      context 'no authenticators are loaded' do
        it "returns empty list of authenticators" do
          retrieve_authenticators('/authenticators/rspec/', current_user)
          expect(response.code).to eq('200')
          expect(response.body).to eql('{"authenticators":[],"count":0}')
          expect(log_output.string).to include("conjur: rspec:user:tester successfully listed authenticators with URI path: '/authenticators/rspec'\n")
        end
      end
      context 'When authenticators are loaded' do
        before do
          apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
        end
        it "returns the authenticators" do
          retrieve_authenticators('/authenticators/rspec/', current_user)
          expect(response.code).to eq('200')
          expect(JSON.parse(response.body)["count"]).to eql(3)
          expect(log_output.string).to include("conjur: rspec:user:tester successfully listed authenticators with URI path: '/authenticators/rspec'\n")
        end
        context 'When you filter for oidc' do
          it "returns only the oidc authenticators" do
            retrieve_authenticators('/authenticators/rspec?type=oidc', current_user)
            expect(response.code).to eq('200')
            expect(JSON.parse(response.body)["count"]).to eql(1)
            expect(log_output.string).to include("conjur: rspec:user:tester successfully listed authenticators with URI path: '/authenticators/rspec'\n")
          end
        end
      end
    end
    context 'There is an unhandled error' do
      before do
        allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:find_all).and_raise("test error")
      end
      it 'creates an audit log for that error' do
        retrieve_authenticators('/authenticators/rspec?type=authn-oidc', current_user)
        expect(response.code).to eq('500')
        expect(log_output.string).to include("conjur: rspec:user:tester failed to list authenticators with URI path: '/authenticators/rspec': test error\n")
      end
    end
  end

  describe '#authenticator_enablement' do
    before do
      allow(Audit).to receive(:logger).and_return(Audit::Log::RubyAdapter.new(logger))
    end
    context 'when user has permissions' do
      context 'no authenticators are loaded' do
        it "returns a 404" do
          enable_request("{ \"enabled\": true }", current_user, resource_id: 'jwt/foo')
          expect(response.code).to eq('404')
          expect(response.body).to eql("{\"code\":\"404\",\"message\":\"Authenticator: authn-jwt/foo not found in account 'rspec'\"}")
          expect(log_output.string).to include("rspec:user:tester failed to enable authn-jwt foo with URI path: '/authenticators/rspec/jwt/foo'")
        end
      end
      context 'When authenticators are loaded' do
        before do
          apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
        end
        context 'when you set enablement to true and false' do
          it "disables/enables and then returns the authenticator" do
            # enable the authenticator initially
            enable_request("{ \"enabled\": true }", current_user)
            expect(response.code).to eq('200')
            expect(JSON.parse(response.body)["enabled"]).to eq(true)

            # disable the authenticator
            enable_request("{ \"enabled\": false }", current_user)
            expect(response.code).to eq('200')
            expect(JSON.parse(response.body)["enabled"]).to eq(false)
            expect(log_output.string).to include(
              "conjur: rspec:user:tester successfully enabled authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' " \
              "and JSON object: { \"enabled\": false }\n"
            )
          end
        end
        context 'There is an unhandled error' do
          before do
            allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:find).and_raise("test error")
          end
          it 'creates an audit log for that error' do
            enable_request("{ \"enabled\": true }", current_user)
            expect(response.code).to eq('500')
            expect(log_output.string).to include(
              "conjur: rspec:user:tester failed to enable authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' " \
              "and JSON object: { \"enabled\": true }: test error\n"
            )
          end
        end
        context 'When current user does not have full privileges' do
          let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
          context 'When current user has update permissions' do
            it "returns and updates the authenticator" do
              enable_request("{\"enabled\": true }", current_user)
              expect(response.code).to eq('200')
              expect(JSON.parse(response.body)["enabled"]).to eq(true)
              expect(log_output.string).to include(
                "conjur: rspec:user:alice successfully enabled authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' " \
                "and JSON object: {\"enabled\": true }\n"
              )
            end
          end
          context 'When current user does not have update permissions' do
            it "returns a 403" do
              enable_request("{\"enabled\": true }", current_user, resource_id: "oidc/keycloak")
              expect(response.code).to eq('403')
              expect(JSON.parse(response.body)["message"]).to eq("CONJ00006E 'alice' does not have 'update' privilege on rspec:webservice:conjur/authn-oidc/keycloak")
              expect(log_output.string).to include(
                "conjur: rspec:user:alice failed to enable authn-oidc keycloak with URI path: '/authenticators/rspec/oidc/keycloak' " \
                "and JSON object: {\"enabled\": true }: CONJ00006E 'alice' does not have 'update' privilege on rspec:webservice:conjur/authn-oidc/keycloak\n"
              )
            end
          end
        end
        context 'When request body is malformed' do
          context 'When missing param enablement' do
            it "returns a 422" do
              enable_request("{}", current_user)
              expect(response.code).to eq('422')
              expect(log_output.string).to include(
                "conjur: rspec:user:tester failed to enable authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' and JSON object: {}: Missing required parameter: enabled"
              )
            end
          end
          context 'When request body is empty' do
            it "returns a 400" do
              enable_request("", current_user)
              expect(response.code).to eq('400')
              expect(log_output.string).to include(
                "conjur: rspec:user:tester failed to enable authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1': Request body is empty"
              )
            end
          end
          context 'When there are extra paramaters in request body' do
            it "returns a 422" do
              enable_request("{\"type\": \"aws\", \"enabled\": true }", current_user)
              expect(response.code).to eq('422')
              expect(log_output.string).to include(
                "conjur: rspec:user:tester failed to enable authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' " \
                "and JSON object: {\"type\": \"aws\", \"enabled\": true }: The following parameters were not expected: 'type'"
              )
            end
          end
          context 'When enabled is not a boolean' do
            it "returns a 422" do
              enable_request("{\"enabled\": 1 }", current_user)
              expect(response.code).to eq('422')
              expect(log_output.string).to include(
                "conjur: rspec:user:tester failed to enable authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1' " \
                "and JSON object: {\"enabled\": 1 }: The enabled parameter must be of type=boolean"
              )
            end
          end
        end
      end
    end
  end

  describe '#create_authenticator' do
    before do
      allow(Audit).to receive(:logger).and_return(Audit::Log::RubyAdapter.new(logger))
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user has permissions' do
      it "returns a 201" do
        create_request(current_user)
        expect(response.code).to eq('201')
        expect((JSON.parse(response.body)["name"])).to eql("test-jwt3")
        expect(log_output.string).to include(
          "conjur: rspec:user:tester successfully created jwt test-jwt3 with URI path: '/authenticators/rspec' and JSON object: " \
          "{\"type\":\"jwt\",\"name\":\"test-jwt3\",\"enabled\":false,\"data\":{\"jwks_uri\":\"http://uri\",\"identity\":" \
          "{\"token_app_property\":\"prop\",\"enforced_claims\":[\"test\",\"123\"],\"claim_aliases\":{\"myclaim\":\"myvalue\",\"second\":\"two\"}}},\"annotations\":{\"test\":\"123\"}}\n"
        )
      end

      context 'when the authenticator already exists in the database' do
        it "returns a 409" do
          create_request(current_user, id: 'test-jwt1')
          expect(response.code).to eq('409')
          expect((JSON.parse(response.body)["message"])).to eql("The authenticator already exists.")
          expect(log_output.string).to include(
            "conjur: rspec:user:tester failed to create jwt test-jwt1 with URI path: '/authenticators/rspec' and JSON object: " \
            "{\"type\":\"jwt\",\"name\":\"test-jwt1\",\"enabled\":false,\"data\":{\"jwks_uri\":\"http://uri\",\"identity\":" \
            "{\"token_app_property\":\"prop\",\"enforced_claims\":[\"test\",\"123\"],\"claim_aliases\":{\"myclaim\":\"myvalue\",\"second\":\"two\"}}},\"annotations\":{\"test\":\"123\"}}: " \
            "The authenticator already exists.\n"
          )
        end
      end
    end

    context 'when user does not have create permission' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
      it "returns a 403" do
        create_request(current_user)
        expect(response.code).to eq('403')
        expect(log_output.string).to include("Forbidden")
      end
    end

    context 'when the request body is malformed JSON' do
      it "returns a 400" do
        post(
          "/authenticators/rspec",
          env: token_auth_header(role: current_user).merge(
            'RAW_POST_DATA' => "not a valid json",
            'ACCEPT' => "application/x.secretsmgr.v2beta+json",
            'CONTENT_TYPE' => "application/json"
          )
        )
        expect(response.code).to eq('400')
        expect(JSON.parse(response.body)["message"]).to eq("Request JSON is malformed")
        expect(log_output.string).to include("conjur: rspec:user:tester failed to create authenticator with URI path: '/authenticators/rspec'")
      end
    end

    context 'when user does not have visibility on auth branch' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:bob') }

      it "returns a 404" do
        create_request(current_user)
        expect(response.code).to eq('404')
        expect(log_output.string).to include("rspec:policy:conjur/authn-jwt not found in account rspec")
      end
    end

    context 'when user doesnt have visibility on the requested owner' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:grant') }
      let(:owner) { { id: "bob", kind: "user" } }

      it "returns a 404" do
        create_request(current_user, owner: owner)
        expect(response.code).to eq('404')
        expect(log_output.string).to include("rspec:user:bob not found in account rspec")
      end
    end

    context 'when the requested owner doesnt exist' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:grant') }
      let(:owner) { { id: "bob", kind: "host" } }

      it "returns a 404" do
        create_request(current_user, owner: owner)
        expect(response.code).to eq('404')
        expect(log_output.string).to include("rspec:host:bob not found in account rspec")
      end
    end
    context 'when the request body is malformed JSON' do
      it "returns a 400" do
        post(
          "/authenticators/rspec",
          env: token_auth_header(role: current_user).merge(
            'RAW_POST_DATA' => "not a valid json",
            'ACCEPT' => "application/x.secretsmgr.v2beta+json",
            'CONTENT_TYPE' => "application/json"
          )
        )
        expect(response.code).to eq('400')
        expect(JSON.parse(response.body)["message"]).to eq("Request JSON is malformed")
        expect(log_output.string).to include("conjur: rspec:user:tester failed to create authenticator with URI path: '/authenticators/rspec'")
      end
    end
    context 'There is an unhandled error' do
      before do
        allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:create).and_raise("test error")
      end
      it 'creates an audit log for that error' do
        create_request(current_user, id: 'test-jwt1')
        expect(response.code).to eq('500')
        expect(log_output.string).to include("conjur: rspec:user:tester failed to create authenticator with URI path: '/authenticators/rspec'")
      end
    end
  end

  describe '#delete_authenticator' do
    before do
      allow(Audit).to receive(:logger).and_return(Audit::Log::RubyAdapter.new(logger))
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user has permissions' do
      context 'the authenticator does not exist' do
        it "returns a 404" do
          delete_authenticator('jwt', 'foo', current_user)
          expect(response.code).to eq('404')
          expect(log_output.string).to include("conjur: rspec:user:tester failed to delete authn-jwt foo with URI path: '/authenticators/rspec/jwt/foo'")
        end
      end
      context 'the authenticator exists' do
        it "deletes the authenticator" do
          delete_authenticator('jwt', 'test-jwt1', current_user)
          expect(response.code).to eq('204')
          expect(log_output.string).to include("conjur: rspec:user:tester successfully deleted authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1'")
        end
      end
      context 'There is an unhandled error' do
        before do
          allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:delete).and_raise("test error")
        end
        it 'creates an audit log for that error' do
          delete_authenticator('jwt', 'test-jwt1', current_user)
          expect(response.code).to eq('500')
          expect(log_output.string).to include("conjur: rspec:user:tester failed to delete authn-jwt test-jwt1 with URI path: '/authenticators/rspec/jwt/test-jwt1'")
        end
      end
    end
    context 'when user does not have delete permission' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
      it "returns a 403" do
        delete_authenticator('oidc', 'keycloak', current_user)
        expect(response.code).to eq('403')
        expect(log_output.string).to include("conjur: rspec:user:alice failed to delete authn-oidc keycloak with URI path: '/authenticators/rspec/oidc/keycloak'")
      end
    end
  end

  # testing request body validations by table for readability
  describe '#authenticator_enablement' do
    [
      {
        case: 'when the request body is empty',
        body: "",
        expected_response: "Request body is empty",
        expected_code: '400'
      },
      {
        case: 'when enablement isnt a bool',
        body: "{ \"enabled\": \"test\" }",
        expected_response: "The enabled parameter must be of type=boolean",
        expected_code: '422'
      },
      {
        case: 'when enablement isnt a in the body',
        body: "{ \"config\": \"test\" }",
        expected_response: "Missing required parameter: enabled",
        expected_code: '422'
      },
      {
        case: 'the body is not valid json',
        body: "test",
        expected_response: "Request JSON is malformed",
        expected_code: '400'
      },
      {
        case: 'when request body has extra keys',
        body: "{ \"config\": \"test\", \"enabled\": false, \"name\": \"test-jwt1\" }",
        expected_response: "The following parameters were not expected: 'config, name'",
        expected_code: '422'
      }
    ].each do |test_case|
      context test_case[:case].to_s do
        it "returns an exception" do
          enable_request(test_case[:body], current_user)
          expect(response.code).to eq(test_case[:expected_code])
          expect(JSON.parse(response.body)["message"]).to eq(test_case[:expected_response])
        end
      end
    end
  end

  describe '#total_count' do
    before do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end

    it "preserves total count with limit parameter" do
      retrieve_authenticators('/authenticators/rspec?limit=1', current_user)
      expect(response.code).to eq('200')
      body = JSON.parse(response.body)
      expect(body["authenticators"].length).to eq(1)
      expect(body["count"]).to eq(3)
    end

    it "preserves total count with offset parameter" do
      retrieve_authenticators('/authenticators/rspec?offset=1', current_user)
      expect(response.code).to eq('200')
      body = JSON.parse(response.body)
      expect(body["authenticators"].length).to eq(2)
      expect(body["count"]).to eq(3)
    end

    it "preserves total count with both limit and offset parameters" do
      retrieve_authenticators('/authenticators/rspec?limit=1&offset=1', current_user)
      expect(response.code).to eq('200')
      body = JSON.parse(response.body)
      expect(body["authenticators"].length).to eq(1)
      expect(body["count"]).to eq(3)
    end

    context 'with type filtering' do
      it "preserves type count with limit parameter" do
        retrieve_authenticators('/authenticators/rspec?type=jwt&limit=1', current_user)
        expect(response.code).to eq('200')
        body = JSON.parse(response.body)
        expect(body["authenticators"].length).to eq(1)
        expect(body["count"]).to eq(2)
        expect(body["authenticators"].first["type"]).to eq("jwt")
      end

      it "preserves type count with offset parameter" do
        retrieve_authenticators('/authenticators/rspec?type=jwt&offset=1', current_user)
        expect(response.code).to eq('200')
        body = JSON.parse(response.body)
        expect(body["authenticators"].length).to eq(1)
        expect(body["count"]).to eq(2)
        expect(body["authenticators"].first["type"]).to eq("jwt")
      end

      context 'and user restricions' do
        context 'user with limited access' do
          let(:current_user) { Role.find_or_create(role_id: 'rspec:user:restricted_user') }

          it "count reflects only authenticators user can access" do
            retrieve_authenticators('/authenticators/rspec', current_user)
            expect(response.code).to eq('200')
            body = JSON.parse(response.body)
            expect(body["authenticators"].length).to eq(1)
            expect(body["count"]).to eq(1)
            expect(body["authenticators"].first["name"]).to eq("test-jwt1")
          end

          it "type filtering with restrictions may show zero results" do
            retrieve_authenticators('/authenticators/rspec?type=oidc', current_user)
            expect(response.code).to eq('200')
            body = JSON.parse(response.body)
            expect(body["authenticators"].length).to eq(0)
            expect(body["count"]).to eq(0)
          end
        end

        context 'user with no access' do
          let(:current_user) { Role.find_or_create(role_id: 'rspec:user:bob') }

          it "count shows zero when user has no authenticator access" do
            retrieve_authenticators('/authenticators/rspec', current_user)
            expect(response.code).to eq('200')
            body = JSON.parse(response.body)
            expect(body["authenticators"].length).to eq(0)
            expect(body["count"]).to eq(0)
          end
        end
      end
    end
  end
end
