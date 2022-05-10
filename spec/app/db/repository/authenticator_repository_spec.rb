# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::AuthenticatorRepository') do
  let(:repo) { DB::Repository::AuthenticatorRepository.new() }

  describe('exists method') do
    context "with missing parameters" do
      it "returns false with no parameters" do
        expect(repo.exists?(type: nil, account: nil, service_id: nil)).to eq (false)
      end

      it "returns false with no type parameter" do
        expect(repo.exists?(type: nil, account: "rspec", service_id: "abc123")).to eq(false)
      end

      it "returns false with no account parameter" do
        expect(repo.exists?(type: "oidc", account: nil, service_id: "abc123")).to eq(false)
      end

      it "returns false with no service_id parameter" do
        expect(repo.exists?(type: "oidc", account: "rspec", service_id: nil)).to eq(false)
      end
    end

    context "all params" do
      it "returns false if the resource doesn't exist" do
        expect(repo.exists?(type: "oidc", account: "rspec", service_id: "abc123")).to eq(false)
      end

      it "returns true if the resource does exist" do
        ::Role.create(
          role_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
          owner_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        expect(repo.exists?(type: "oidc", account: "rspec", service_id: "abc123")).to eq(true)
      end
    end
  end

  describe("find") do
    context "missing parameters" do
      it "returns nil with no parameters" do
        expect(repo.find(type: nil, account: nil, service_id: nil)).to be_nil
      end

      it "returns nil with no type parameter" do
        expect(repo.find(type: nil, account: "rspec", service_id: "abc123")).to be_nil
      end

      it "returns nil with no account parameter" do
        expect(repo.find(type: "oidc", account: nil, service_id: "abc123")).to be_nil
      end

      it "returns nil with no service_id parameter" do
        expect(repo.find(type: "oidc", account: "rspec", service_id: nil)).to be_nil
      end
    end

    context "no variables are set" do
      it "returns nil when the authenticator doesn't exist" do
        expect(repo.find(type: "oidc", account: "rspec", service_id: "abc123")).to be_nil
      end
    end

    context "no variables are set" do
      before do
        ::Role.create(
          role_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
          owner_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
      end

      it "returns an authenticator with no variables set" do
        authenticator = repo.find(type: "oidc", account: "rspec", service_id: "abc123")
        expect(authenticator).to be_truthy
        expect(authenticator.class.to_s).to eq("Authenticator::OidcAuthenticator")
        expect(authenticator.account).to eq("rspec")
        expect(authenticator.service_id).to eq("abc123")
        expect(authenticator.required_payload_parameters).to be_nil
        expect(authenticator.name).to be_nil
        expect(authenticator.provider_uri).to be_nil
        expect(authenticator.response_type).to be_nil
        expect(authenticator.client_id).to be_nil
        expect(authenticator.client_secret).to be_nil
        expect(authenticator.claim_mapping).to be_nil
        expect(authenticator.state).to be_nil
        expect(authenticator.nonce).to be_nil
        expect(authenticator.redirect_uri).to be_nil
        expect(authenticator.is_valid?).to be_falsey
        expect(authenticator.version).to be_nil
      end
    end

    context "variables are set no secrets created" do
      before do
        ::Role.create(
          role_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
          owner_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Role.create(
          role_id: "rspec:webservice:conjur/authn-oidc/abc123",
        )

        [:required_payload_parameters, :name, :provider_uri, :response_type,
         :client_id, :client_secret, :claim_mapping, :state, :nonce, :redirect_uri]
          .each do |variable|
          ::Resource.create(
            resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
            owner_id: "rspec:webservice:conjur/authn-oidc/abc123"
          )
        end
      end

      it "returns an authenticator with no variables set" do
        authenticator = repo.find(type: "oidc", account: "rspec", service_id: "abc123")
        expect(authenticator).to be_truthy
        expect(authenticator.class.to_s).to eq("Authenticator::OidcAuthenticator")
        expect(authenticator.account).to eq("rspec")
        expect(authenticator.service_id).to eq("abc123")
        expect(authenticator.required_payload_parameters).to be_nil
        expect(authenticator.name).to be_nil
        expect(authenticator.provider_uri).to be_nil
        expect(authenticator.response_type).to be_nil
        expect(authenticator.client_id).to be_nil
        expect(authenticator.client_secret).to be_nil
        expect(authenticator.claim_mapping).to be_nil
        expect(authenticator.state).to be_nil
        expect(authenticator.nonce).to be_nil
        expect(authenticator.redirect_uri).to be_nil
        expect(authenticator.is_valid?).to be_falsey
        expect(authenticator.version).to be_nil
      end

    end

    context "variables are set with secrets created for a v2 authenticator" do
      before do
        ::Role.create(
          role_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
          owner_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Role.create(
          role_id: "rspec:webservice:conjur/authn-oidc/abc123",
        )

        [:required_payload_parameters, :name, :provider_uri, :response_type,
          :client_id, :client_secret, :claim_mapping, :state, :nonce, :redirect_uri]
          .each do |variable|
          ::Resource.create(
            resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
            owner_id: "rspec:webservice:conjur/authn-oidc/abc123"
          )
          ::Secret.create(
            resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
            value: "#{variable}abc123"
          )
        end
      end

      it "returns a v2 authenticator with all properties set" do
        authenticator = repo.find(type: "oidc", account: "rspec", service_id: "abc123")
        expect(authenticator).to be_truthy
        expect(authenticator.class.to_s).to eq("Authenticator::OidcAuthenticator")
        expect(authenticator.account).to eq("rspec")
        expect(authenticator.service_id).to eq("abc123")
        expect(authenticator.required_payload_parameters).to be_truthy
        expect(authenticator.required_payload_parameters[0]).to eq("required_payload_parametersabc123")
        expect(authenticator.name).to eq("nameabc123")
        expect(authenticator.provider_uri).to eq("provider_uriabc123")
        expect(authenticator.response_type).to eq("response_typeabc123")
        expect(authenticator.client_id).to eq("client_idabc123")
        expect(authenticator.client_secret).to eq("client_secretabc123")
        expect(authenticator.claim_mapping).to eq("claim_mappingabc123")
        expect(authenticator.state).to eq("stateabc123")
        expect(authenticator.nonce).to eq("nonceabc123")
        expect(authenticator.redirect_uri).to eq("redirect_uriabc123")
        expect(authenticator.is_valid?).to be_truthy
        expect(authenticator.version).to eq(Authenticator::OidcAuthenticator::AUTH_VERSION_2)
      end
    end

    context "variables are set with secrets created for a v1 authenticator" do
      before do
        ::Role.create(
          role_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Resource.create(
          resource_id: "rspec:webservice:conjur/authn-oidc/abc123",
          owner_id: "rspec:policy:conjur/authn-oidc/abc123"
        )
        ::Role.create(
          role_id: "rspec:webservice:conjur/authn-oidc/abc123",
          )

        [:provider_uri, :id_token_user_property]
          .each do |variable|
          ::Resource.create(
            resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
            owner_id: "rspec:webservice:conjur/authn-oidc/abc123"
          )
          ::Secret.create(
            resource_id: "rspec:variable:conjur/authn-oidc/abc123/#{variable}",
            value: "#{variable}abc123"
          )
        end
      end

      it "returns a v2 authenticator with all properties set" do
        authenticator = repo.find(type: "oidc", account: "rspec", service_id: "abc123")
        expect(authenticator).to be_truthy
        expect(authenticator.class.to_s).to eq("Authenticator::OidcAuthenticator")
        expect(authenticator.account).to eq("rspec")
        expect(authenticator.service_id).to eq("abc123")
        expect(authenticator.required_payload_parameters).to be_truthy
        expect(authenticator.required_payload_parameters[0]).to eq(:credentials)
        expect(authenticator.name).to be_nil
        expect(authenticator.provider_uri).to eq("provider_uriabc123")
        expect(authenticator.response_type).to be_nil
        expect(authenticator.client_id).to be_nil
        expect(authenticator.client_secret).to be_nil
        expect(authenticator.claim_mapping).to eq("id_token_user_propertyabc123")
        expect(authenticator.state).to be_nil
        expect(authenticator.nonce).to be_nil
        expect(authenticator.redirect_uri).to be_nil
        expect(authenticator.is_valid?).to be_truthy
        expect(authenticator.version).to eq(Authenticator::OidcAuthenticator::AUTH_VERSION_1)
      end
    end
  end
end