require 'spec_helper'

describe LoginController, :type => :controller do
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }

  context "#login" do
    shared_examples_for "successful authentication" do
      it "succeeds" do
        post :login, params
        expect(response).to be_ok
        expect(response.body.length).to be >= 44
      end
    end
    
    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        post :login, account: account
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      it_should_behave_like "authentication denied"
    end
    context "when user doesn't exist" do
      let(:basic_password) { "the-password" }
      include_context "authenticate Basic"
      it_should_behave_like "authentication denied"
    end
    context "when user exists" do
      include_context "create user"
      context "with basic auth" do
        let(:basic_password) { api_key }
        include_context "authenticate Basic"
        it_should_behave_like "successful authentication"
      end
      context "with Token auth" do
        include_context "authenticate Token"
        it_should_behave_like "authentication denied"
      end
    end
  end
end
