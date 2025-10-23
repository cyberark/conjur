# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe AuthenticateController, :type => :request do
  before(:all) do
    DatabaseCleaner.clean_with(:truncation)
    Role.create(role_id: 'rspec:user:admin')
  end

  include_context "existing account"

  let(:password) { "The-Password1" }
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }
  let(:service_id) { "db" }
  let(:authenticator) { "authn" }

  let(:authenticate_url) do
    "/#{authenticator}/#{account}/#{login}/authenticate"
  end
  let(:login_url) do
    "/#{authenticator}/#{account}/login"
  end

  context "#login" do
    shared_examples_for "successful login" do
      it "succeeds" do
        get(login_url, env: request_env)
        expect(response).to be_ok
        expect(response.body).to eq(api_key)
      end
    end

    context "without authentication" do
      it "is unauthorized" do
        post(authenticate_url)
        expect(response.code).to eq("401")
      end
    end

    context "when user doesn't exist" do
      let(:basic_password) { "the-password" }
      include_context "authenticate Basic"

      it "is unauthorized" do
        post(authenticate_url, env: request_env)
        expect(response.code).to eq("401")
      end
    end

    context "when user exists" do
      include_context "create user"

      context "with basic auth" do
        let(:basic_password) { api_key }
        include_context "authenticate Basic"
        it_should_behave_like "successful login"
      end

      context "with Token auth" do
        include_context "authenticate Token"

        it "is unauthorized" do
          post(authenticate_url, env: request_env)
          expect(response.code).to eq("401")
        end
      end
    end
  end

  describe "#authenticate" do
    include_context "create user"

    RSpec::Matchers.define(:have_valid_token_for) do |login|
      match do |response|
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json(response.body)
        expect(token.claims['sub']).to eq(login)
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end
    end

    def invoke
      payload = { 'RAW_POST_DATA' => the_user.credentials.api_key }
      post(authenticate_url, env: payload)
    end

    context "with api key" do
      context 'when API key is valid' do
        it "succeeds" do
          invoke
          expect(response).to have_valid_token_for(login)
        end
      end

      context 'when API key is invalid' do
        it "fails" do
          post(authenticate_url, env: { 'RAW_POST_DATA' => 'foo-bar-baz' })
          expect(response.code).to eq("401")
          expect(response.body).to eq("")
        end
      end

      it "is fast", :performance do
        expect{ invoke }.to handle(30).requests_per_second
      end
    end
  end

  context "when incorrectly using GET method" do
    include_context "create user"

    it "does not route" do
      expect do
        Rails.application.routes.recognize_path(authenticate_url, method: :get)
      end.to raise_error(ActionController::RoutingError, /No route matches/)
    end

    it "does not log that the authenticator is not enabled" do
      allow(Rails.logger).to receive(:info)
      payload = { 'RAW_POST_DATA' => the_user.credentials.api_key }

      expect(Rails.logger).not_to receive(:info).with(/is not enabled/)

      begin
        get(authenticate_url, env: payload)
      rescue ActionController::RoutingError
        # This error is expected, we want to ensure the log doesn't contain
        # the misleading message.
      end
    end
  end

  context "invalid basic authorization header passed" do
    include_context "invalid authenticate Basic"

    it "is unauthorized" do
      post(authenticate_url, env: request_env)
      expect(response.code).to eq("401")
    end
  end

  context "authenticator update action" do
    let(:test_policy) do
      <<~POLICY
        - !policy
          id: conjur/authn/db
          body:
          - !webservice

        - !policy
          id: conjur/authn-k8s/db
          body:
          - !webservice
      POLICY
    end

    context 'when you set authenticator to true and false' do
      let(:admin_request_env) do
        token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
        { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
      end

      def apply_root_policy(account, policy_content:, expect_success: false)
        post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
        return unless expect_success

        expect(response.code).to eq("201")
      end

      def authenticator_up_request(body, current_user, url_path)
        patch(
          url_path,
          env: token_auth_header(role: current_user).merge(
            'RAW_POST_DATA' => body,
            'CONTENT_TYPE' => "application/json"
          )
        )
      end

      before do
        apply_root_policy(account, policy_content: test_policy, expect_success: true)
      end

      let(:authenticator_up) { "authn-k8s" }
      let(:update_authenticator_url) { "/#{authenticator_up}/#{service_id}/#{account}" }
      let(:current_user) { Role.find_or_create(role_id: "#{account}:user:admin") }

      it "is enabled" do
        payload = { enabled: true }
        authenticator_up_request(payload.to_json, current_user, update_authenticator_url)
        expect(response.code).to eq('204')
      end

      it "is disabled" do
        payload = { enabled: false }
        authenticator_up_request(payload.to_json, current_user, update_authenticator_url)
        expect(response.code).to eq('204')
      end
    end
  end

  before(:all) { Slosilo["authn:rspec"] ||= Slosilo::Key.new }
end
