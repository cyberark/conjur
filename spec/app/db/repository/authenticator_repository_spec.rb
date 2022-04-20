# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::AuthenticatorRepository') do

  describe('exists method') do
    context "with missing parameters" do
      before do
        @resource = double("::Resource")
        allow(@resource).to receive(:[]).and_return(@resource)
        allow(@resource).to receive(:exists?).and_return(false)
      end

      it "returns false with no parameters" do
        expect(@resource).to receive(:[]).with(":webservice:conjur/authn-/")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(repo.exists?(type: nil, account: nil, service_id: nil)).to eq (false)
      end

      it "returns false with no type parameter" do
        expect(@resource).to receive(:[]).with("rspec:webservice:conjur/authn-/abc123")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.exists?(type: nil, account: "rspec", service_id: "abc123")
        ).to eq(false)
      end

      it "returns false with no account parameter" do
        expect(@resource).to receive(:[]).with(":webservice:conjur/authn-oidc/abc123")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.exists?(type: "oidc", account: nil, service_id: "abc123")
        ).to eq(false)
      end

      it "returns false with no service_id parameter" do
        expect(@resource).to receive(:[]).with("rspec:webservice:conjur/authn-oidc/")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.exists?(type: "oidc", account: "rspec", service_id: nil)
        ).to eq(false)
      end
    end

    context "all params" do
      before do
        @resource = double("::Resource")
      end

      it "returns false if the resource doesn't exist" do
        allow(@resource).to receive(:[]).and_return(@resource)
        allow(@resource).to receive(:exists?).and_return(false)
        expect(@resource).to receive(:[]).with("rspec:webservice:conjur/authn-oidc/abc123")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.exists?(type: "oidc", account: "rspec", service_id: "abc123")
        ).to eq(false)
      end

      it "returns true if the resource does exist" do
        allow(@resource).to receive(:[]).and_return(@resource)
        allow(@resource).to receive(:exists?).and_return(true)
        expect(@resource).to receive(:[]).with("rspec:webservice:conjur/authn-oidc/abc123")

        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.exists?(type: "oidc", account: "rspec", service_id: "abc123")
        ).to eq(true)
      end
    end
  end

  describe("find") do
    context "missing parameters" do
      before do
        @resource = double("::Resource")
        allow(@resource).to receive(:[]).and_return(@resource)
        allow(@resource).to receive(:exists?).and_return(false)
      end

      it "returns nil with no parameters" do
        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(repo.find(type: nil, account: nil, service_id: nil)).to be_nil
      end

      it "returns nil with no type parameter" do
        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.find(type: nil, account: "rspec", service_id: "abc123")
        ).to be_nil
      end

      it "returns nil with no account parameter" do
        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.find(type: "oidc", account: nil, service_id: "abc123")
        ).to be_nil
      end

      it "returns nil with no service_id parameter" do
        repo = DB::Repository::AuthenticatorRepository.new(
          resource_repository: @resource
        )
        expect(
          repo.find(type: "oidc", account: "rspec", service_id: nil)
        ).to be_nil
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
        @repo = DB::Repository::AuthenticatorRepository.new()
      end

      it "returns an authenticator with no variables set" do
        authenticator = @repo.find(type: "oidc", account: "rspec", service_id: "abc123")
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
        @repo = DB::Repository::AuthenticatorRepository.new()
      end

      it "returns an authenticator with no variables set" do
        authenticator = @repo.find(type: "oidc", account: "rspec", service_id: "abc123")
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
      end

    end

    context "variables are set with secrets created" do
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
        @repo = DB::Repository::AuthenticatorRepository.new()
      end

      it "returns an authenticator with all properties set" do
        authenticator = @repo.find(type: "oidc", account: "rspec", service_id: "abc123")
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
      end
    end
  end
end