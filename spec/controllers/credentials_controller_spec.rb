# frozen_string_literal: true

require 'spec_helper'

describe CredentialsController, :type => :controller do
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
  
  context "#rotate_api_key" do
    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        post :rotate_api_key, account: account
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
          post :rotate_api_key, account: account
          the_user.credentials.reload
          expect(response.code).to eq("200")
          expect(response.body).to eq(the_user.credentials.api_key)
          expect(the_user.credentials.api_key).to_not eq(basic_password)
        end
      end
    end
  end
  
  context "#update_password" do
    let(:new_password) { +"new-password" }
    context "without auth" do
      it "is unauthorized" do
        post :update_password, account: account
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
              message: "password must not be blank",
              details: [
                {
                  code: "validation_failed",
                  target: "password",
                  message: "must not be blank"
                }
              ]
            }
          }
        }
        it "is is malformed" do
          post :update_password, account: account
          expect(response.code).to eq("422")
          expect(response.body).to eq(errors.to_json)
        end
      end
      context "with post body" do
        before { request.env['RAW_POST_DATA'] = new_password }
        context "and valid password" do
          it "updates the password" do
            post :update_password, account: account
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
                message: "password cannot contain a newline",
                details: [
                  {
                    code: "validation_failed",
                    target: "password",
                    message: "cannot contain a newline"
                  }
                ]
              }
            }
          }
          it "reports the error" do
            post :update_password, account: account
            expect(response.code).to eq("422")
            expect(response.body).to eq(errors.to_json)
            expect(the_user.credentials.authenticate(new_password)).to be(false)
          end
        end
      end
    end
  end
end
