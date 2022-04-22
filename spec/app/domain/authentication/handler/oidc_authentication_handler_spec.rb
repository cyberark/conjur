require 'spec_helper'

RSpec.describe('Authentication::Handler::OidcAuthenticationHandler') do
  describe('authenticate') do
    context "account doesn't exist" do
      it "will raise an error" do
        role_cls = class_double("::Role")
        handler = Authentication::Handler::OidcAuthenticationHandler.new(
          role_repository_class: role_cls
        )
        allow(role_cls).to receive(:with_pk).and_return(nil)
        expect(role_cls).to receive(:with_pk)
        expect {
          handler.authenticate(account: "rspec", service_id: "abc123", parameters: {})
        }.to raise_error(Errors::Authentication::Security::AccountNotDefined)
      end
    end

    context "authenticator doesn't exist" do
      it "will raise an error" do
        role_cls = class_double("::Role")
        repo = double("DB::Repository::AuthenticatorRepository")
        handler = Authentication::Handler::OidcAuthenticationHandler.new(
          authenticator_repository: repo,
          role_repository_class: role_cls
        )
        allow(role_cls).to receive(:with_pk).and_return(::Role.new)
        allow(repo).to receive(:find).with(anything()).and_return(nil)
        expect {
          handler.authenticate(account: "rspec", service_id: "abc123", parameters: {})
        }.to raise_error(Errors::Authentication::AuthenticatorNotSupported)
      end
    end

    context "authenticator exists" do
      context "but not valid" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls
          )
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123"
            )
          )
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123", parameters: {})
          }.to raise_error(Errors::Authentication::AuthenticatorNotSupported)
        end
      end

      context "not enabled" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls
          )
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123", parameters: {})
          }.to raise_error(Errors::Authentication::AuthenticatorNotSupported)
        end
      end
    end

    context "good authenticator" do
      context "required parameter is missing" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls
          )
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123", parameters: {})
          }.to raise_error("Required parameter code is missing from parameters")
        end
      end

      context "state param doesn't match stored value" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
          )
          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )

          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "asdfab", code: "1244556" })
          }.to raise_error("State Mismatch")
        end
      end

      context "client throws error fetching access token" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_raise("error")
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556" })
          }.to raise_error("error")
        end
      end

      context "get an error when decoding the id token" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_raise("error decoding token")
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556" })
          }.to raise_error("error decoding token")
        end
      end

      context "get an error when verifying the token" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")
          jwt = double("JSON::JWT")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_return(jwt)
          allow(jwt).to receive(:verify!).with(anything()).and_raise("error verifying")
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556" })
          }.to raise_error("error verifying")
        end
      end

      context "no matching conjur role" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")
          jwt = double("JSON::JWT")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_return(jwt)
          allow(jwt).to receive(:verify!).with(anything())
          allow(jwt).to receive(:raw_attributes).and_return({})
          allow(role_cls).to receive(:from_username).with(anything(), anything()).and_return(nil)
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556" })
          }.to raise_error(Errors::Authentication::Security::RoleNotFound)
        end
      end

      context "conjur role cannot use authenticator" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          resource_cls = class_double("::Resource")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            resource_repository_class: resource_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")
          jwt = double("JSON::JWT")
          role = double("::Role")
          resource = double("::Resource")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_return(jwt)
          allow(jwt).to receive(:verify!).with(anything())
          allow(jwt).to receive(:raw_attributes).and_return({})
          allow(role_cls).to receive(:from_username).with(anything(), anything()).and_return(role)
          allow(role).to receive(:identifier).and_return("123")
          allow(resource_cls).to receive(:[]).with('rspec/webservice/authn-oidc/abc123').and_return(resource)
          allow(role).to receive(:allowed_to?).with('authenticate', resource).and_return(false)
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556" })
          }.to raise_error(Errors::Authentication::Security::RoleNotAuthorizedOnResource)
        end
      end

      context "ip address doesn't match cidr" do
        it "will raise an error" do
          role_cls = class_double("::Role")
          resource_cls = class_double("::Resource")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            resource_repository_class: resource_cls,
            oidc_util: oidc_util
          )
          oidc_client = double("::OpenIDConnect::Client")
          jwt = double("JSON::JWT")
          role = double("::Role")
          resource = double("::Resource")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_return(jwt)
          allow(jwt).to receive(:verify!).with(anything())
          allow(jwt).to receive(:raw_attributes).and_return({})
          allow(role_cls).to receive(:from_username).with(anything(), anything()).and_return(role)
          allow(role).to receive(:identifier).and_return("123")
          allow(resource_cls).to receive(:[]).with('rspec/webservice/authn-oidc/abc123').and_return(resource)
          allow(role).to receive(:allowed_to?).with('authenticate', resource).and_return(true)
          allow(role).to receive(:valid_origin?).with("127.0.0.1").and_return(false)
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect {
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556", client_ip: "127.0.0.1" })
          }.to raise_error(Errors::Authentication::InvalidOrigin)
        end
      end

      context "successful" do
        it "will received a signed token" do
          role_cls = class_double("::Role")
          resource_cls = class_double("::Resource")
          repo = double("DB::Repository::AuthenticatorRepository")
          oidc_util = double("Authentication::Util::OidcUtil")
          token_factory = double("TokenFactory")
          handler = Authentication::Handler::OidcAuthenticationHandler.new(
            authenticator_repository: repo,
            role_repository_class: role_cls,
            resource_repository_class: resource_cls,
            oidc_util: oidc_util,
            token_factory: token_factory
          )
          oidc_client = double("::OpenIDConnect::Client")
          jwt = double("JSON::JWT")
          role = double("::Role")
          resource = double("::Resource")

          Rails.application.config.conjur_config.authenticators = ["authn", "authn-oidc/abc123"]
          allow(oidc_client).to receive(:authorization_code=)
          allow(oidc_util).to receive(:client).and_return(oidc_client)
          allow(role_cls).to receive(:with_pk).and_return(::Role.new)
          allow(repo).to receive(:find).with(anything()).and_return(
            Authenticator::OidcAuthenticator.new(
              account: "rspec",
              service_id: "abc123",
              required_payload_parameters: [:code, :state],
              name: "test",
              provider_uri: "http://test.com",
              response_type: "code",
              client_id: "client-id-192",
              client_secret: "nf3i2h0f2w0hfei20f",
              claim_mapping: "username",
              state: "statei0o3n",
              nonce: "noneo0j3409jhas",
              redirect_uri: "https://conjur.com"
            )
          )
          allow(oidc_client).to receive(:access_token!).and_return(
            Class.new do
              def id_token
                "12344"
              end
            end.new
          )
          allow(oidc_util).to receive(:decode_token).with(anything()).and_return(jwt)
          allow(jwt).to receive(:verify!).with(anything())
          allow(jwt).to receive(:raw_attributes).and_return({})
          allow(role_cls).to receive(:from_username).with(anything(), anything()).and_return(role)
          allow(role).to receive(:identifier).and_return("123")
          allow(resource_cls).to receive(:[]).with('rspec/webservice/authn-oidc/abc123').and_return(resource)
          allow(role).to receive(:allowed_to?).with('authenticate', resource).and_return(true)
          allow(role).to receive(:valid_origin?).with("127.0.0.1").and_return(true)
          allow(role).to receive(:identity).and_return("authn-oidc/abc123")
          allow(token_factory).to receive(:signed_token).with(account: "rspec", username: "authn-oidc/abc123").and_return("asdlkfnaon")
          expect(oidc_client).to receive(:authorization_code=).with("1244556")
          expect(
            handler.authenticate(account: "rspec", service_id: "abc123",
                                 parameters: { state: "statei0o3n", code: "1244556", client_ip: "127.0.0.1" })
          ).to eq("asdlkfnaon")
        end
      end
    end
  end
end
