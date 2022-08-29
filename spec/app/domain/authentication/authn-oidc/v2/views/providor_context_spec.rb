# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Views::ProviderContext') do
  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(current_client)
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:discovery_information).and_return(endpoint)
    end
  end

  # ToDo - remove
  let(:endpoint) { double(authorization_endpoint: '"http://test"') }

  let(:foo) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "foo",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      provider_uri: "http://test",
      name: "foo",
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: 'claim_mapping'
    )
  end

  let(:bar) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "bar",
      provider_uri: "http://test",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      name: "bar",
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: 'claim_mapping'
    )
  end

  let(:authenticators) {[foo, bar]}

  let(:res) do
    [{
      name: "foo",
      redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&state=state&code_challenge=qjrzSW9gMiUgpUvqgEPE4_-8swvyCtfOVvg55o5S_es&code_challenge_method=S256&nonce=nonce&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
      service_id: "foo",
      type: "authn-oidc",
      nonce: 'nonce',
      state: 'state',
      code_verifier: 'M25iVXpKU3puUjFaYWg3T1NDTDQtcW1ROUY5YXlwalNoc0hhakxifmZHag'
    }, {
      name: "bar",
      redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&state=state&code_challenge=qjrzSW9gMiUgpUvqgEPE4_-8swvyCtfOVvg55o5S_es&code_challenge_method=S256&nonce=nonce&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
      service_id: "bar",
      type: "authn-oidc",
      nonce: 'nonce',
      state: 'state',
      code_verifier: 'M25iVXpKU3puUjFaYWg3T1NDTDQtcW1ROUY5YXlwalNoc0hhakxifmZHag'
    }]
  end

  let(:security_object) do
    class_double(::Authentication::AuthnOidc::V2::DataObjects::SecurityAttributes).tap do |double|
      allow(double).to receive(:new).and_return(
        Authentication::AuthnOidc::V2::DataObjects::SecurityAttributes.new(
          nonce: 'nonce',
          state: 'state',
          code_verifier: 'M25iVXpKU3puUjFaYWg3T1NDTDQtcW1ROUY5YXlwalNoc0hhakxifmZHag'
        )
      )
    end
  end

  let(:provider_context) do
    ::Authentication::AuthnOidc::V2::Views::ProviderContext.new(
      client: client,
      security_obj: security_object
    )
  end

  describe('#call') do
    context 'when multiple authenticators exist' do
      it 'returns the providers object with the redirect urls' do
        expect(provider_context.call(authenticators: authenticators))
          .to eq(res)
      end
    end

    context 'when there are no authenticators ' do
      it 'returns an empty array' do
        expect(provider_context.call(authenticators: []))
          .to eq([])
      end
    end
  end
end
