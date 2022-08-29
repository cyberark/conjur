# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Strategies::Token') do
  let(:jwt) { double(raw_attributes: { claim_mapping: 'alice' }) }

  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: 'cucumber',
      service_id: 'foo',
      redirect_uri: 'http://conjur/authn-oidc/cucumber/authenticate',
      provider_uri: 'http://test',
      name: 'foo',
      state: 'foostate',
      client_id: 'ConjurClient',
      client_secret: 'client_secret',
      claim_mapping: claim_mapping,
      nonce: 'secret'
    )
  end

  let(:claim_mapping) { 'claim_mapping' }

  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(
        current_client
      )
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:validate_token).and_return(jwt)
    end
  end

  let(:strategy) do
    Authentication::AuthnOidc::V2::Strategies::Token.new(
      authenticator: authenticator,
      client: client
    )
  end

  describe('#callback') do
    context 'when bearer token' do
      context 'is nil' do
        it 'raises an error' do
          expect{strategy.callback(nil) }.to raise_error(
            Errors::Authentication::AuthnOidc::MissingBearerToken
          )
        end
      end

      context 'is empty' do
        it 'raises an error' do
          expect{strategy.callback('') }.to raise_error(
            Errors::Authentication::AuthnOidc::MissingBearerToken
          )
        end
      end
    end

    context 'when a role_id matching the bearer token identity exist' do
      it 'returns the role' do
        expect(strategy.callback(jwt))
          .to eq('alice')
      end
    end
  end
end


RSpec.describe('Authentication::AuthnOidc::V2::Strategies::Code') do
  let(:jwt) { double(raw_attributes: { claim_mapping: 'alice' }) }

  let(:authenticator) do
    Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
      account: 'cucumber',
      service_id: 'foo',
      redirect_uri: 'http://conjur/authn-oidc/cucumber/authenticate',
      provider_uri: 'http://test',
      name: 'foo',
      state: 'foostate',
      client_id: 'ConjurClient',
      client_secret: 'client_secret',
      claim_mapping: claim_mapping,
      nonce: 'secret'
    )
  end

  let(:claim_mapping) { 'claim_mapping' }

  let(:client) do
    class_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:new).and_return(
        current_client
      )
    end
  end

  let(:current_client) do
    instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
      allow(double).to receive(:validate_code).and_return(jwt)
    end
  end

  let(:strategy) do
    Authentication::AuthnOidc::V2::Strategies::Code.new(
      authenticator: authenticator,
      client: client
    )
  end

  describe('#callback') do
    context 'when parameters are missing' do
      it 'raises error with an empty hash' do
        expect{strategy.callback({}) }.to raise_error(
          Errors::Authentication::RequestBody::MissingRequestParam,
          "CONJ00009E Field 'code' is missing or empty in request body"
        )
      end

      context "when 'code'" do
        context 'is missing' do
          it 'raises an error' do
            expect{strategy.callback({ state: '' }) }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam,
              "CONJ00009E Field 'code' is missing or empty in request body"
            )
          end
        end

        context 'is empty' do
          it 'raises an error' do
            expect{strategy.callback({ code: '', state: '' }) }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam,
              "CONJ00009E Field 'code' is missing or empty in request body"
            )
          end
        end
      end

      context "when the 'state'" do
        context 'is missing' do
          it 'raises an error' do
            expect{strategy.callback({ code: 's' }) }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam,
              "CONJ00009E Field 'state' is missing or empty in request body"
            )
          end
        end

        context 'is empty' do
          it 'raises an error' do
            expect{strategy.callback({ code: 's', state: '' }) }.to raise_error(
              Errors::Authentication::RequestBody::MissingRequestParam,
              "CONJ00009E Field 'state' is missing or empty in request body"
            )
          end
        end

        context 'does not match the authenticator configured state' do
          it 'raises an error' do
            expect { strategy.callback({ state: 'barstate', code: 'code' }) }
              .to raise_error(Errors::Authentication::AuthnOidc::StateMismatch)
          end
        end
      end
    end

    context 'when a role_id matching the identity exist' do
      it 'returns the role' do
        expect(strategy.callback({ state: 'foostate', code: 'code' }))
          .to eq('alice')
      end
    end

    context 'when the claiming matching in the token does not match the jwt' do
      let(:claim_mapping) { 'wrong_mapping' }
      it 'raises an error' do
        expect { strategy.callback({ state: 'foostate', code: 'code' }) }
          .to raise_error(Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty)
      end
    end
  end
end

RSpec.describe('Authentication::AuthnOidc::V2::Strategies::Utilities') do
  let(:utilities) { Authentication::AuthnOidc::V2::Strategies::Utilities }

  describe '.resolve_identity' do
    let(:jwt) { double(raw_attributes: attributes) }
    context 'when mapping value' do
      context 'is in jwt' do
        let(:attributes) { { email: 'user@company.com' } }
        it 'returns the desired value' do
          expect(
            utilities.resolve_identity(
              jwt: jwt,
              claim_mapping: :email
            )
          ).to eq('user@company.com')
        end
      end

      context 'is not in jwt' do
        let(:attributes) { {} }
        it 'raises an exception' do
          expect { utilities.resolve_identity(jwt: jwt, claim_mapping: :foo) }.to raise_error(
            Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
          )
        end
      end
    end
  end
end
