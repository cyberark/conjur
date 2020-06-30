# frozen_string_literal: true

require 'spec_helper'

describe CredentialsController, :type => :request do
  include_context "existing account"

  before(:all) { Slosilo["authn:rspec"] ||= Slosilo::Key.new }

  let(:login) { "u-#{random_hex}" }
  let(:account) { "rspec" }
  let(:authenticator) { "authn" }
  let(:authenticate_url) do
    "/#{authenticator}/#{account}/#{login}/authenticate"
  end
  let(:login_url) do
    "/#{authenticator}/#{account}/login"
  end
  let(:update_password_url) do
    "/authn/#{account}/password"
  end
  let(:update_api_key_url) do
    "/#{authenticator}/#{account}/api_key"
  end
  
  context "#rotate_api_key" do

    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        put(update_api_key_url, env: request_env)
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      let(:request_env) { {} } # empty hash
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
          put(update_api_key_url, env: request_env)
          the_user.credentials.reload
          expect(response.code).to eq("200")
          expect(response.body).to eq(the_user.credentials.api_key)
          expect(the_user.credentials.api_key).to_not eq(basic_password)
        end
      end
    end
  end
  
  context "#update_password" do
    let(:new_password) { "New-Password1" }
    let(:insufficient_msg) do
      ::Errors::Conjur::InsufficientPasswordComplexity.new.to_s
    end

    context "without auth" do
      it "is unauthorized" do
        put(update_password_url)
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
          put(update_password_url, env: request_env)
          expect(response.code).to eq("422")
          expect(response.body).to eq(errors.to_json)
        end
      end

      context "with post body" do
        let(:full_env) { pw_payload.merge(request_env) }

        context "and valid password" do
          let(:pw_payload) { { 'RAW_POST_DATA' => new_password } }

          it "updates the password" do
            put(update_password_url, env: full_env)
            expect(response.code).to eq("204")

            # verify new password works
            the_user.credentials.reload
            can_auth = the_user.credentials.authenticate(new_password)
            expect(can_auth).to be(true)
          end
        end

        context "and invalid password" do
          let(:pw_payload) { { 'RAW_POST_DATA' => "the\npassword" } }
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
            put(update_password_url, env: full_env)
            expect(response.code).to eq("422")
            expect(response.body).to eq(errors.to_json)
            can_auth = the_user.credentials.authenticate(new_password)
            expect(can_auth).to be(false)
          end
        end
      end
    end
  end
end
