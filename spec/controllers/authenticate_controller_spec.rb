# frozen_string_literal: true

require 'spec_helper'

describe AuthenticateController, :type => :controller do
  let(:password) { "The-Password1" }
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }
  let(:authenticator) { "authn" }

  context "#login" do
    shared_examples_for "successful login" do
      it "succeeds" do
        post :login, params
        expect(response).to be_ok
        expect(response.body).to eq(api_key)
      end
    end
    
    shared_examples_for "login denied" do
      it "is unauthorized" do
        post :login, account: account, authenticator: authenticator
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      it_should_behave_like "login denied"
    end

    context "when user doesn't exist" do
      let(:basic_password) { "the-password" }
      include_context "authenticate Basic"
      it_should_behave_like "login denied"
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
        it_should_behave_like "login denied"
      end
    end
  end

  describe "#authenticate" do
    include_context "create user"
    
    RSpec::Matchers.define :have_valid_token_for do |login|
      match do |response|
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json response.body
        expect(token.claims['sub']).to eq(login)
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end
    end
    
    def invoke
      post :authenticate, { authenticator: 'authn', account: account, id: login }
    end
    
    def self.it_succeeds
      it "succeeds" do
        invoke
        expect(response).to have_valid_token_for(login)
      end
    end
    
    def self.it_fails
      it "fails" do
        invoke
        expect(response).to_not be_ok
        expect{ JSON.parse response.body }.to raise_error
      end
    end
    
    def self.it_fails_with status_code
      it "fails with #{status_code}" do
        invoke
        expect(response).not_to be_ok
        expect(response.code).to eq(status_code.to_s)
      end
    end
    
    # context "with password" do
    #   before { request.env['RAW_POST_DATA'] = password }
    #   it_fails_with 401
    # end
    
    context "with api key" do
      before { request.env['RAW_POST_DATA'] = the_user.credentials.api_key }
      it_succeeds

      it "is fast", :performance do
        expect{ invoke }.to handle(30).requests_per_second
      end
    end

    # context "with non-existent user" do
    #   def invoke
    #     post :authenticate, authenticator: 'authn', account: account, id: 'santa-claus'
    #   end

    #   it_fails_with 401
      
    #   it "is fast", :performance do
    #     expect{ invoke }.to handle(30).requests_per_second
    #   end
    # end
  end

  before(:all) { Slosilo["authn:rspec"] ||= Slosilo::Key.new }
end
