# frozen_string_literal: true

require 'spec_helper'

describe CredentialsController, :type => :request do
  include_context "existing account"

  before(:all) { Slosilo["authn:rspec"] ||= Slosilo::Key.new }

  let(:login) { "u-#{random_hex}" }
  let(:host_login) { "h-#{random_hex}" }
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

    context "with token auth" do
      include_context "create user"
      include_context "authenticate Token"
      let(:pw_payload) { { 'RAW_POST_DATA' => new_password } }
      let(:errors) {
        {
          error: {
            code: "unauthorized",
            message: "Credential strength is insufficient"
          }
        }
      }
      it "is unauthorized" do
        put(update_password_url, env: request_env)
        expect(response.code).to eq("401")
        expect(response.body).to eq(errors.to_json)
      end
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

    context "with host basic auth" do
      let(:basic_password) { host_api_key }
      include_context "create host"
      include_context "host authenticate Basic"
      let(:the_host) { create_host(host_login) }

      context "with post body" do
        let(:full_env) { pw_payload.merge(request_env) }

        context "and valid password" do
          let(:pw_payload) { { 'RAW_POST_DATA' => new_password } }

          it "reports the error" do
            put(update_password_url, env: full_env)
            expect(response.code).to eq("403")
            can_auth = the_host.credentials.authenticate(new_password)
            expect(can_auth).to be(false)
          end
        end
      end
    end
  end

  describe "#api_key_last_rotated" do
    let(:get_api_key_last_rotated_url) { "/#{authenticator}/#{account}/api_key" }
    
    context "authentication required" do
      it "requires authentication" do
        get(get_api_key_last_rotated_url)
        expect(response.code).to eq("401")
      end
    end

    context "with basic auth" do
      include_context "authenticate Basic"
      include_context "create user"
      let(:basic_password) { api_key }

      it "returns JSON with role and ISO 8601 formatted timestamp" do
        test_timestamp = Time.parse("2025-01-15 10:30:00 UTC")
        Sequel::Model.db[:credentials].where(role_id: the_user.role_id).update(updated_at: test_timestamp)
        
        get(get_api_key_last_rotated_url, env: request_env)
        
        expect(response.code).to eq("200")
        expect(response.content_type).to eq("application/json; charset=utf-8")
        
        json_response = JSON.parse(response.body)
        expect(json_response["role"]).to eq(the_user.role_id)
        expect(json_response["timestamp"]).to eq("2025-01-15T10:30:00Z")
      end

      it "handles null timestamp with empty timestamp in JSON" do
        # Set updated_at to NULL to test the edge case
        Sequel::Model.db[:credentials].where(role_id: the_user.role_id).update(updated_at: nil)
        
        get(get_api_key_last_rotated_url, env: request_env)
        
        expect(response.code).to eq("200")
        expect(response.content_type).to eq("application/json; charset=utf-8")
        
        json_response = JSON.parse(response.body)
        expect(json_response["role"]).to eq(the_user.role_id)
        expect(json_response["timestamp"]).to eq("")
      end
    end

    context "cross-user access with basic auth" do
      include_context "authenticate Basic"
      include_context "create user"
      let(:basic_password) { api_key }

      let(:other_user_login) { "other-#{random_hex}" }
      let(:other_user) { create_user(other_user_login) }
      let(:get_other_user_url) { "#{get_api_key_last_rotated_url}?role=user:#{other_user_login}" }

      it "denies access" do
        other_user
        the_user
        
        get(get_other_user_url, env: request_env)
        expect(response.code).to eq("401")
      end
    end

    context "cross-user access with token auth" do
      include_context "create user"
      include_context "authenticate Token"
      
      let(:other_user_login) { "other-#{random_hex}" }
      let(:other_user) { create_user(other_user_login) }
      let(:get_other_user_url) { "#{get_api_key_last_rotated_url}?role=user:#{other_user_login}" }

      it "denies access without privilege" do
        get(get_other_user_url, env: request_env)
        expect(response.code).to eq("404")
      end

      it "denies access with read-only privilege" do
        Permission.create(
          resource: other_user.resource,
          privilege: 'read',
          role: the_user
        )
        
        get(get_other_user_url, env: request_env)
        expect(response.code).to eq("403")
      end

      it "allows access with update privilege" do
        Permission.create(
          resource: other_user.resource,
          privilege: 'update',
          role: the_user
        )
        test_timestamp = Time.parse("2025-02-20 15:45:00 UTC")
        Sequel::Model.db[:credentials].where(role_id: other_user.role_id).update(updated_at: test_timestamp)
        
        get(get_other_user_url, env: request_env)
        
        expect(response.code).to eq("200")
        expect(response.content_type).to eq("application/json; charset=utf-8")
        
        json_response = JSON.parse(response.body)
        expect(json_response["role"]).to eq(other_user.role_id)
        expect(json_response["timestamp"]).to eq("2025-02-20T15:45:00Z")
      end
    end

    context "with host basic auth" do
      include_context "create host"
      include_context "host authenticate Basic"
      let(:basic_password) { host_api_key }
      let(:host_account) { account }
      let(:the_host) { create_host(host_login) }

      it "allows host to read its own timestamp" do
        test_timestamp = Time.parse("2025-03-10 12:00:00 UTC")
        Sequel::Model.db[:credentials].where(role_id: the_host.role_id).update(updated_at: test_timestamp)
        
        get(get_api_key_last_rotated_url, env: request_env)
        
        expect(response.code).to eq("200")
        expect(response.content_type).to eq("application/json; charset=utf-8")
        
        json_response = JSON.parse(response.body)
        expect(json_response["role"]).to eq(the_host.role_id)
        expect(json_response["timestamp"]).to eq("2025-03-10T12:00:00Z")
      end
    end

    context "with invalid role parameter" do
      include_context "create user"
      include_context "authenticate Basic"
      let(:basic_password) { api_key }

      it "returns 404 for nonexistent role" do
        get("#{get_api_key_last_rotated_url}?role=user:nonexistent", env: request_env)
        expect(response.code).to eq("404")
      end

      it "returns 404 for malformed role" do
        get("#{get_api_key_last_rotated_url}?role=invalid-role-format", env: request_env)
        expect(response.code).to eq("422")
      end
    end
  end
end
