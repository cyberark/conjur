# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

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

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201") 
  end  

  let(:test_policy) do
    <<~POLICY
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
          privilege: [ authenticate ]
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
    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  describe '#find_authenticator' do
    before do
      apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
    end
    context 'when user is an admin' do
      context 'The authenticator does not exisit in policy' do
        it "returns an authenticator" do
          get(
            '/authenticators/cucumber/authn-jwt/foo',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('404')
        end
      end
      context 'the authenticator is loaded in policy' do
        it "returns an authenticator" do
          get(
            '/authenticators/rspec/authn-jwt/test-jwt1',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('200')
        end
      end
      context 'When current user is not an admins' do
        let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
        it "returns an authenticator when theres read aceess" do
          get(
            '/authenticators/rspec/authn-oidc/keycloak',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('200')
        end
        it "returns a 403 when its only visible" do
          get(
            '/authenticators/rspec/authn-jwt/test-jwt1',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('403')
        end
      end
    end
  end
  describe '#list_authenticators' do
    context 'when user has permission' do
      context 'no authenticators are loaded' do
        it "returns empty list authenticator" do
          get(
            '/authenticators/rspec/',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('200')
          expect(response.body).to eql('{"authenticators":[],"count":0}')
        end
      end
      context 'When authenticators are loaded' do
        before do
          apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
        end
        it "returns an authenticator" do
          get(
            '/authenticators/rspec/',
            env: token_auth_header(role: current_user)
          )
          expect(response.code).to eq('200')
          expect(JSON.parse(response.body)["count"]).to eql(2)
        end
        context 'When you filter for oidc' do
          it "returns only the oidc authenticator" do
            get(
              '/authenticators/rspec?type=authn-oidc',
              env: token_auth_header(role: current_user)
            )
            expect(response.code).to eq('200')
            expect(JSON.parse(response.body)["count"]).to eql(1)
          end
        end
      end
    end
  end
end
