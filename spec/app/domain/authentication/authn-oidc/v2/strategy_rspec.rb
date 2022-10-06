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
      client_id: "ConjurClient",
      client_secret: 'client_secret',
      claim_mapping: mapping
    )
  end

  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(current_client)
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

  describe('#callback') do
    context 'when a role_id matches the identity exist' do
      let(:mapping) { "claim_mapping" }
      it 'returns the role' do
        expect(strategy.callback(nonce: 'nonce', code: 'code', code_verifier: 'foo'))
          .to eq('alice')
      end
    end

    context "when the claiming matching in the token doesn't match the jwt" do
      let(:mapping) { 'wrong_mapping' }
      it 'raises a `IdTokenClaimNotFoundOrEmpty` error' do
        expect { strategy.callback(code: 'code', nonce: 'nonce', code_verifier: 'foo') }
          .to raise_error(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
      end
    end

    context 'when required parameters are missing' do
      let(:mapping) { '' }
      context 'when code is missing' do
        it 'raises a `MissingRequestParam` error' do
          expect { strategy.callback(nonce: 'nonce', code_verifier: 'foo') }
            .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
      context 'when nonce is missing' do
        it 'raises a `MissingRequestParam` error' do
          expect { strategy.callback(code: 'code', code_verifier: 'foo') }
            .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
      context 'when code_verifier is missing' do
        it 'raises a `MissingRequestParam` error' do
          expect { strategy.callback(nonce: 'nonce', code: 'code') }
            .to raise_error(Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
    end
  end
end
