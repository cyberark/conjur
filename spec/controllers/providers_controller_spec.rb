# frozen_string_literal: true

require 'spec_helper'

describe Authenticators::Oidc::ProvidersController, :type => :controller do
  let(:user) { double('my-user', role_id: 'rspec:user:admin') }
  let(:params) { { account: 'cucumber' } }
  let(:endpoint) { double(authorization_endpoint: '"http://test"') }
  let(:repo) { DB::Repository::AuthenticatorRepository.new }
  let(:handler) { Authentication::Handler::OidcAuthenticationHandler.new }
  let(:controller) { Authenticators::Oidc::ProvidersController.new }
  let(:authenticator) { Authenticator::OidcAuthenticator.new(account: "cucumber", service_id: "abc", provider_uri: "http://test") }
  let(:authenticators) do
    [
      Authenticator::OidcAuthenticator.new(account: "cucumber", service_id: "abc", provider_uri: "http://test", name: "abc"),
      Authenticator::OidcAuthenticator.new(account: "cucumber", service_id: "123", provider_uri: "http://test2", name: "123")
    ]
  end
  let(:media_type) { 'application/octet-stream' }
  let(:res) {[{ login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "abc" },
              { login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "123" }]}

  let(:option) { { account: "cucumber" } }
  context "user requests to see configured authenticators" do
    it 'finds one authenticator' do
      allow_any_instance_of(::Authentication::Util::OidcUtil).to receive(:discovery_information).and_return(endpoint)
      allow_any_instance_of(Authentication::Handler::OidcAuthenticationHandler).to receive(:can_use_authenticator?).and_return(true)
      allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:find).and_return(authenticator)
      expect(controller.authenticator(role: user, repository: repo, handler: handler, account: "cucumber", service_id: "abc"))
        .to eq("\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=")
    end
    it 'finds all authenticator' do
      allow_any_instance_of(::Authentication::Util::OidcUtil).to receive(:discovery_information).and_return(endpoint)
      allow_any_instance_of(Authentication::Handler::OidcAuthenticationHandler).to receive(:can_use_authenticator?).and_return(true)
      allow_any_instance_of(DB::Repository::AuthenticatorRepository).to receive(:find_all).and_return(authenticators)
      expect(controller.authenticators(role: user, repository: repo, handler: handler, account: "cucumber"))
        .to eq([{ login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "abc" },
                { login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "123" }])
    end

    it 'finds all authenticator' do
      allow_any_instance_of(Authenticators::Oidc::ProvidersController).to receive(:assumed_role).and_return(user)
      allow_any_instance_of(Authenticators::Oidc::ProvidersController).to receive(:options).and_return(params)
      allow_any_instance_of(ActionController::Metal).to receive(:new)
      allow_any_instance_of(Authenticators::Oidc::ProvidersController).to receive(:query_role).and_return(user)
      allow_any_instance_of(Authenticators::Oidc::ProvidersController).to receive(:authenticators).and_return(res)
      expect(controller.index)
        .to eq([{ login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "abc" },
                { login_url:  "\"http://test\"?client_id=&response_type=&scope=&state=&nonce=&redirect_uri=", name: "123" }])
    end
  end
end
