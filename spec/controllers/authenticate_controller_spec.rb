# frozen_string_literal: true

require 'spec_helper'

describe AuthenticateController, :type => :request do
  include_context "existing account"

  let(:password) { "The-Password1" }
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }
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
        include_context "authenticate user Token"

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
      it "succeeds" do
        invoke
        expect(response).to have_valid_token_for(login)
      end

      it "is fast", :performance do
        expect{ invoke }.to handle(30).requests_per_second
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

  before(:all) { init_slosilo_keys("rspec") }
end
