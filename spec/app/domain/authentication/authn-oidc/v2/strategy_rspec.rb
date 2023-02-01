# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(' Authentication::AuthnOidc::V2::Strategy') do

  let(:jwt) { double(raw_attributes: { claim_mapping: "alice" }) }

  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: "cucumber",
      service_id: "foo",
      redirect_uri: "http://conjur/authn-oidc/cucumber/authenticate",
      provider_uri: "http://test",
      name: "foo",
      state: 'foostate',
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: mapping,
      nonce: 'secret'
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
      allow(double).to receive(:callback).and_return(jwt)
    end
  end

  let(:strategy) do
    Authentication::AuthnOidc::V2::Strategy.new(
      authenticator: authenticator,
      client: client
    )
  end

  describe('#callback', :type => 'unit') do
    context 'when a role_id matches the identity exist' do
      let(:mapping) { "claim_mapping" }
      it 'returns the role' do
        expect(strategy.callback({ state: "foostate", code: "code" }))
          .to eq("alice")
      end
    end

    context 'When the authn state doesnt match the arguments' do
      let(:mapping) { "claim_mapping" }
      it 'raises an error' do
        expect { strategy.callback({ state: "barstate", code: "code" }) }
          .to raise_error(Errors::Authentication::AuthnOidc::StateMismatch)
      end
    end

    context 'When the claiming matching in the token doesnt match the jwt' do
      let(:mapping) { "wrong_mapping" }
      it 'raises an error' do
        expect { strategy.callback({ state: "foostate", code: "code" }) }
          .to raise_error(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
      end
    end
  end
end
