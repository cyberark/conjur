# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Views::ProviderContext') do
  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(
        current_client)
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:discovery_information).and_return(endpoint)
    end
  end

  let(:endpoint) { double(authorization_endpoint: '"http://test"') }

  let(:foo) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator
      .new(account: "cucumber",
           service_id: "foo",
           redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
           provider_uri: "http://test",
           name: "foo",
           state: 'foostate',
           client_id: "ConjurClient",
           client_secret: 'client_secret',
           claim_mapping: 'claim_mapping',
           nonce: 'secret',
           )
  end

  let(:bar) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator
      .new(account: "cucumber",
           service_id: "bar",
           provider_uri: "http://test",
           redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
           name: "bar",
           state: 'barstate',
           client_id: "ConjurClient",
           client_secret: 'client_secret',
           claim_mapping: 'claim_mapping',
           nonce: 'secret')
  end

  let(:authenticators) {[foo, bar]}

  let(:res) do
    [{ name: "foo",
       redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&state=foostate&nonce=secret&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
       service_id: "foo",
       type: "authn-oidc" },
     { name: "bar",
       redirect_uri: "\"http://test\"?client_id=ConjurClient&response_type=code&scope=openid%20email%20profile" \
         "&state=barstate&nonce=secret&redirect_uri=http%3A%2F%2Fconjur%2Fauthn-oidc%2Fcucumber%2Fauthenticate",
       service_id: "bar",
       type: "authn-oidc" }]
  end

  let(:provider_context) do
    ::Authentication::AuthnOidc::V2::Views::ProviderContext.new(
      client: client
    )
  end

  describe('#call') do
    context 'when provider context is given multiple authenticators' do
      it 'returns the providers object with the redirect urls' do
        expect(provider_context.call(authenticators: authenticators))
          .to eq(res)
      end
    end

    context 'when provider context is  given no authenticators ' do
      it 'returns an empty array' do
        expect(provider_context.call(authenticators: []))
          .to eq([])
      end
    end
  end
end

