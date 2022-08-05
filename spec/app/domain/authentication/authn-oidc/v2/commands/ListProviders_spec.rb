require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Commands::ListProviders') do

  let(:provider_context) do
    ::Authentication::AuthnOidc::V2::Views::ProviderContext.new(
      client: client
    )
  end

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

  let(:authenticator_repo) do
    instance_double(::DB::Repository::AuthenticatorRepository).tap do |double|
      allow(double).to receive(:find_all).and_return(authenticators)
    end
  end

  let(:foo) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator
      .new(account: "cucumber",
           service_id: "foo",
           redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
           provider_uri: "https://google.com",
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
           provider_uri: "https://google.com",
           redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
           name: "bar",
           state: 'barstate',
           client_id: "ConjurClient",
           client_secret: 'client_secret',
           claim_mapping: 'claim_mapping',
           nonce: 'secret')
  end

  let(:authenticators) {[foo, bar]}


  let(:list_providers)  do
    Authentication::AuthnOidc::V2::Commands::ListProviders.new(
      authenticatorRepository: authenticator_repo,
      provider: provider_context
    )
  end

  describe('#call') do
    context 'when list providers is called with an account' do
      it 'returns the providers object with the redirect urls' do
        expect(list_providers.call(
          message: { account: 'cucumber' }.to_json
        ))
          .to eq(res)
      end
    end

    context 'when list providers is called without an account' do
      it 'raises an error to say account is required' do
        expect do
          list_providers.call(
            message: { service_id: 'cucumber' }.to_json
          )
        end.to raise_error("'account' is required")
      end
    end

    context 'when list providers is called without an message' do
      it 'raises an error to say account is required' do
        expect do
          list_providers.call(
          )
        end.to raise_error("missing keyword: :message")
      end
    end
  end
end