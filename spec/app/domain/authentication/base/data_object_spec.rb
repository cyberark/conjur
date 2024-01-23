# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Base::DataObject) do
  let(:default_oidc_args) do
    {
      provider_uri: 'https://foo.bar.com/baz',
      client_id: 'client-id-123',
      client_secret: 'client-secret-123',
      claim_mapping: 'email',
      account: 'default',
      service_id: 'my-authenticator'
    }
  end
  let(:oidc_args) { default_oidc_args }
  let(:oidc) { Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(**oidc_args) }

  let(:api_key_args) { { account: 'default' } }
  let(:api_key) { Authentication::AuthnApiKey::V2::DataObjects::Authenticator.new(**api_key_args) }

  describe '.type' do
    it 'describes the child class type' do
      expect(oidc.type).to eq('authn-oidc')
    end
  end

  describe '.identifier' do
    context 'when authenticator has a service id' do
      it 'includes type and service id' do
        expect(oidc.identifier).to eq('authn-oidc/my-authenticator')
      end
    end
    context 'when authenticator does not have a service id' do
      it 'matches the type' do
        expect(api_key.identifier).to eq(api_key.type)
      end
    end
  end

  describe '.resource_id', type: 'unit' do
    context 'when service id is present' do
      it 'includes service id' do
        expect(oidc.resource_id).to eq('default:webservice:conjur/authn-oidc/my-authenticator')
      end
    end
    context 'when authenticator does not require service_id' do
      it 'does not include the webservice' do
        expect(api_key.resource_id).to eq('default:webservice:conjur/authn')
      end
    end
  end

  describe '.token_ttl', type: 'unit' do
    context 'with default initializer' do
      it { expect(api_key.token_ttl).to eq(8.minutes) }
      context 'when authenticator overrides the default' do
        it { expect(oidc.token_ttl).to eq(1.hour) }
      end
    end

    context 'when initialized with a valid duration' do
      let(:oidc_args) { default_oidc_args.merge({ token_ttl: 'PT2H' }) }
      it { expect(oidc.token_ttl).to eq(2.hour)}
    end

    context 'when initialized with an invalid duration' do
      let(:oidc_args) { default_oidc_args.merge({ token_ttl: 'PTinvalidH' }) }
      it 'throws an appropriate error' do
        expect { oidc.token_ttl }.to raise_error(Errors::Authentication::DataObjects::InvalidTokenTTL)
      end
    end
  end
end
