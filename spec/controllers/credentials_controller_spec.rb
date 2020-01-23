# frozen_string_literal: true

require 'spec_helper'

describe CredentialsController, :type => :controller do
  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }
  let(:authenticator) { "authn" }
  
  context "#rotate_api_key" do
    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        post :rotate_api_key, account: account, authenticator: authenticator
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      it_should_behave_like "authentication denied"
    end
    context "with token auth" do
      include_context "create user"
      include_context "authenticate Token"
      it_should_behave_like "authentication denied"
    end
    context "with basic auth" do
      include_context "authenticate Basic"
      context "user not found" do
        let(:basic_password) { "the-password" }
        it_should_behave_like "authentication denied"
      end
      context "on valid user" do
        let(:basic_password) { api_key }
        include_context "create user"
        it "rotates the user's API key" do
          api_key = the_user.api_key
          post :rotate_api_key, account: account, authenticator: authenticator
          the_user.credentials.reload
          expect(response.code).to eq("200")
          expect(response.body).to eq(the_user.credentials.api_key)
          expect(the_user.credentials.api_key).to_not eq(basic_password)
        end
      end
    end
  end
  
  context "#update_password" do
    let(:new_password) { +"New-Password1" }
    let(:insufficient_msg) { ::Errors::Conjur::InsufficientPasswordComplexity.new.to_s }
    context "without auth" do
      it "is unauthorized" do
        post :update_password, account: account, authenticator: authenticator
        expect(response.code).to eq("401")
      end
    end
    context "with basic auth" do
      let(:basic_password) { api_key }
      include_context "create user"
      include_context "authenticate Basic"
      context "without post body" do
        let(:errors) {
          {
            error: {
              code: "validation_failed",
              message: "password #{insufficient_msg}",
              details: [
                {
                  code: "validation_failed",
                  target: "password",
                  message: insufficient_msg
                }
              ]
            }
          }
        }
        it "is is malformed" do
          post :update_password, account: account, authenticator: authenticator
          expect(response.code).to eq("422")
          expect(response.body).to eq(errors.to_json)
        end
      end
      context "with post body" do
        before { request.env['RAW_POST_DATA'] = new_password }
        context "and valid password" do
          it "updates the password" do
            post :update_password, account: account, authenticator: authenticator
            expect(response.code).to eq("204")
            the_user.credentials.reload
            expect(the_user.credentials.authenticate(new_password)).to be(true)
          end
        end
        context "and invalid password" do
          let(:new_password) { +"the\npassword" }
          let(:errors) {
            {
              error: {
                code: "validation_failed",
                message: "password #{insufficient_msg}",
                details: [
                  {
                    code: "validation_failed",
                    target: "password",
                    message: insufficient_msg
                  }
                ]
              }
            }
          }
          it "reports the error" do
            post :update_password, account: account, authenticator: authenticator
            expect(response.code).to eq("422")
            expect(response.body).to eq(errors.to_json)
            expect(the_user.credentials.authenticate(new_password)).to be(false)
          end
        end
      end
    end
  end

  before(:all) { Slosilo["authn:rspec"] ||= Slosilo::Key.new }
end
