require 'spec_helper'

describe LoginController, :type => :controller do
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }

  context "#login_basic" do
    shared_examples_for "successful login" do
      it "succeeds" do
        get :login_basic, params
        expect(response).to be_ok
        expect(response.body.length).to be >= 44
      end
    end
    
    shared_examples_for "login denied" do
      it "is unauthorized" do
        get :login_basic, account: account
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
end
