# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation


# Intergration test for thr V@ authenticator API's
describe AuthenticateController, type: :request do
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

  def enable_request(body, current_user, resource_id: 'authn-jwt/test-jwt1')
    patch(
      "/authenticators/rspec/#{resource_id}",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => body,
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/json"
      )
    )
  end

  def create_body(id)
    {
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
  end

  def create_request(current_user, id = "test-jwt3")
    post(
      "/authenticators/rspec",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => create_body(id).to_json,
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
      - !grant
        role: !group conjur/authn-oidc/keycloak/users
        member: !user alice
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user alice

      - !permit
        role: !user alice
        privilege: [ read ]
        resource: !policy conjur/authn-jwt

    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  describe '#find_authenticator' do
    before do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user is an admin' do
      context 'The authenticator does not exisit in policy' do
        it "returns a 404" do
          retrieve_authenticators('/authenticators/rspec/authn-jwt/foo', current_user)
          expect(response.code).to eq('404')
        end
      end
      context 'the authenticator is loaded in policy' do
        it "returns the authenticator" do
          retrieve_authenticators('/authenticators/rspec/authn-jwt/test-jwt1', current_user)
          expect(response.code).to eq('200')
        end
      end
      context 'When current user is not an admin' do
        let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
        it "returns the authenticator when there is visibility" do
          retrieve_authenticators('/authenticators/rspec/authn-oidc/keycloak', current_user)
          expect(response.code).to eq('200')
        end
      end
    end
  end
  describe '#list_authenticators' do
    context 'when user has permission' do
      context 'no authenticators are loaded' do
        it "returns empty list of authenticators" do
          retrieve_authenticators('/authenticators/rspec/', current_user)
          expect(response.code).to eq('200')
          expect(response.body).to eql('{"authenticators":[],"count":0}')
        end
      end
      context 'When authenticators are loaded' do
        before do
          apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
        end
        it "returns the authenticators" do
          retrieve_authenticators('/authenticators/rspec/', current_user)
          expect(response.code).to eq('200')
          expect(JSON.parse(response.body)["count"]).to eql(2)
        end
        context 'When you filter for oidc' do
          it "returns only the oidc authenticators" do
            retrieve_authenticators('/authenticators/rspec?type=authn-oidc', current_user)
            expect(response.code).to eq('200')
            expect(JSON.parse(response.body)["count"]).to eql(1)
          end
        end
      end
    end
  end

  describe '#authenticator_enablement' do
    context 'when user has permission' do
      context 'no authenticators are loaded' do
        it "returns a 404" do
          enable_request("{ \"enabled\": true }", current_user, resource_id: 'authn-jwt/foo')
          expect(response.code).to eq('404')
          expect(response.body).to eql("{\"code\":\"404\",\"message\":\"Authenticator: authn-jwt/foo not found in account 'rspec'\"}")
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
          end
        end
        context 'When current user is not an admin' do
          let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
          context 'When current user has update permissions' do
            it "returns and updates the authenticator" do
              enable_request("{\"enabled\": true }", current_user)
              expect(response.code).to eq('200')
              expect(JSON.parse(response.body)["enabled"]).to eq(true)
            end
          end
          context 'When current user does not have update permissions' do
            it "returns a 403" do
              enable_request("{\"enabled\": true }", current_user, resource_id: "authn-oidc/keycloak")
              expect(response.code).to eq('403')
              expect(JSON.parse(response.body)["message"]).to eq("CONJ00006E 'alice' does not have 'update' privilege on rspec:webservice:conjur/authn-oidc/keycloak")
            end
          end
        end
      end
    end
  end

  describe '#create_authenticator' do
    before do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user has permission' do
      it "returns a 200" do
        create_request(current_user)
        expect(response.code).to eq('200')
        expect((JSON.parse(response.body)["name"])).to eql("test-jwt3")
      end
      context 'when the authenticator already exisit in the database' do
        it "returns a 409" do
          create_request(current_user, 'test-jwt1')
          expect(response.code).to eq('409')
          expect((JSON.parse(response.body)["message"])).to eql("The authenticator already exists.")
        end
      end
    end
    context 'when user does not have create permission' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
      it "returns a 403" do
        create_request(current_user)
        expect(response.code).to eq('403')
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
        expected_code: '400'
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
end
