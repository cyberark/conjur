# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::DataObjects::Authenticator) do
  let(:default_args) do
    {
      provider_uri: 'https://foo.bar.com/baz',
      client_id: 'client-id-123',
      client_secret: 'client-secret-123',
      claim_mapping: 'email',
      account: 'default',
      service_id: 'my-authenticator'
    }
  end
  let(:args) { default_args }

  let(:authenticator) { described_class.new(**args) }

  describe '.scope', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.scope).to eq('openid email profile') }
    end

    context 'when initialized with a string argument' do
      let(:args) { default_args.merge({ provider_scope: 'foo' }) }
      it { expect(authenticator.scope).to eq('openid email profile foo') }
    end

    context 'when initialized with a non-string argument' do
      let(:args) { default_args.merge({ provider_scope: 1 }) }
      it { expect(authenticator.scope).to eq('openid email profile 1') }
    end

    context 'when initialized with a duplicated argument' do
      let(:args) { default_args.merge({ provider_scope: 'profile' }) }
      it { expect(authenticator.scope).to eq('openid email profile') }
    end

    context 'when initialized with an array argument' do
      context 'single value array' do
        let(:args) { default_args.merge({ provider_scope: 'foo' }) }
        it { expect(authenticator.scope).to eq('openid email profile foo') }
      end

      context 'multi-value array' do
        let(:args) { default_args.merge({ provider_scope: 'foo bar' }) }
        it { expect(authenticator.scope).to eq('openid email profile foo bar') }
      end
    end
  end

  describe '.name', type: 'unit' do
    context 'when name is missing' do
      it { expect(authenticator.name).to eq('My Authenticator') }
    end
    context 'when name is present' do
      let(:args) { default_args.merge(name: 'foo') }
      it { expect(authenticator.name).to eq('foo') }
    end
  end

  describe '.resource_id', type: 'unit' do
    context 'correctly renders' do
      it { expect(authenticator.resource_id).to eq('default:webservice:conjur/authn-oidc/my-authenticator') }
    end
  end

  describe '.response_type', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.response_type).to eq('code') }
    end
  end

  describe '.token_ttl', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.token_ttl).to eq(1.hour) }
    end

    context 'when initialized with a valid duration' do
      let (:args) { default_args.merge({ token_ttl: 'PT2H'}) }
      it { expect(authenticator.token_ttl).to eq(2.hour)}
    end

    context 'when initialized with an invalid duration' do
      let(:args) { default_args.merge({ token_ttl: 'PTinvalidH' }) }
      it {
        expect { authenticator.token_ttl }
          .to raise_error(Errors::Authentication::DataObjects::InvalidTokenTTL)
      }
    end
  end

  describe '.ca_cert', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.ca_cert).to eq(nil) }
    end

    context 'when initialized with a value' do
      let (:args) { default_args.merge({ ca_cert: 'cert'}) }
      it { expect(authenticator.ca_cert).to eq('cert')}
    end
  end
end
