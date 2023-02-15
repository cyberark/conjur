# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::PkceSupportFeature::Views::ProviderContext') do
  let(:client) do
    class_double(::Authentication::AuthnOidc::PkceSupportFeature::Client).tap do |double|
      allow(double).to receive(:new).and_return(current_client)
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::PkceSupportFeature::Client).tap do |double|
      allow(double).to receive(:discovery_information).and_return(endpoint)
    end
  end

  let(:endpoint) { double(authorization_endpoint: '"http://test"') }

  let(:foo) do
    Authentication::AuthnOidc::PkceSupportFeature::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "foo",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      provider_uri: "http://foo",
      name: "foo",
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: 'claim_mapping'
    )
  end

  let(:bar) do
    Authentication::AuthnOidc::PkceSupportFeature::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "bar",
      provider_uri: "http://bar",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      name: "bar",
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: 'claim_mapping'
    )
  end

  let(:authenticators) {[foo, bar]}

  let(:response) do
    [
      {
        name: "foo",
        redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&nonce=random-string&code_challenge=random-sha&code_challenge_method=S256&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
        service_id: "foo",
        type: "authn-oidc",
        nonce: 'random-string',
        code_verifier: 'random-string'
      }, {
        name: "bar",
        redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&nonce=random-string&code_challenge=random-sha&code_challenge_method=S256&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
        service_id: "bar",
        type: "authn-oidc",
        nonce: 'random-string',
        code_verifier: 'random-string'
      }
    ]
  end

  let(:provider_context) do
    ::Authentication::AuthnOidc::PkceSupportFeature::Views::ProviderContext.new(
      client: client,
      random: random,
      digest: digest,
      logger: logger
    )
  end

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  let(:digest) do
    class_double(Digest::SHA256).tap do |double|
      allow(double).to receive(:base64digest).and_return('random-sha')
    end
  end

  let(:random) do
    class_double(SecureRandom).tap do |double|
      allow(double).to receive(:hex).and_return('random-string')
    end
  end

  describe('#call', :type => 'unit') do
    context 'when provider context is given multiple authenticators' do
      it 'returns the providers object with the redirect urls' do
        expect(provider_context.call(authenticators: authenticators))
          .to eq(response)
      end
    end

    context 'when provider context is  given no authenticators ' do
      it 'returns an empty array' do
        expect(provider_context.call(authenticators: []))
          .to eq([])
      end
    end

    context 'when authenticator discovery endpoint is unreachable' do
      let(:current_client) do
        instance_double(::Authentication::AuthnOidc::PkceSupportFeature::Client).tap do |double|
          allow(double).to receive(:discovery_information).and_raise(
            Errors::Authentication::OAuth::ProviderDiscoveryFailed
          )
        end
      end
      it 'does not cause an exception' do
        expect(provider_context.call(authenticators: authenticators)).to eq([])
        expect(log_output.string).to include('WARN')
        %w[foo bar].each do |authenticator|
          expect(log_output.string).to include("Authn-OIDC '#{authenticator}' provider-uri: 'http://#{authenticator}' is unreachable")
        end
      end
    end
  end
end
