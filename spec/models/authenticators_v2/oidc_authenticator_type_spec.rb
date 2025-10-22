require 'spec_helper'

RSpec.describe(AuthenticatorsV2::OidcAuthenticatorType) do
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

  let(:account) { "rspec" }
  let(:args) { default_args }

  let(:authenticator_dict) do
    {
      type: "authn-oidc",
      service_id: "auth1",
      account: account,
      enabled: true,
      owner_id: "#{account}:policy:conjur/authn-oidc",
      annotations: { description: "this is my oidc authenticator" },
      variables: args # No data variables
    }
  end

  let(:authenticator) { described_class.new(authenticator_dict) }

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
      it { expect(authenticator.name).to eq('Auth1') }
    end
    context 'when name is present' do
      let(:args) { default_args.merge(name: 'foo') }
      it { expect(authenticator.name).to eq('foo') }
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
      let(:args) { default_args.merge({ token_ttl: 'PT2H' }) }
      it { expect(authenticator.token_ttl).to eq(2.hour)}
    end

    context 'when initialized with an invalid duration' do
      let(:args) { default_args.merge({ token_ttl: 'PTinvalidH' }) }
      it "raises error" do
        expect do
          authenticator.token_ttl
        end.to raise_error(Errors::Authentication::DataObjects::InvalidTokenTTL)
      end
    end
  end

  describe '.ca_cert', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.ca_cert).to eq(nil) }
    end

    context 'when initialized with a value' do
      let(:args) { default_args.merge({ ca_cert: 'cert' }) }
      it { expect(authenticator.ca_cert).to eq('cert')}
    end
  end

  describe "#to_h" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when all data variables are missing" do
      let(:authenticator_dict) do
        {
          type: "authn-oidc",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-oidc",
          annotations: { description: "this is my oidc authenticator" },
          variables: {} # No data variables
        }
      end

      it "includes the data key as an empty hash in json" do
        json = authenticator.to_h
        expected_json = {
          type: "oidc",
          name: "auth1",
          branch: "conjur/authn-oidc",
          enabled: true,
          owner: { id: "conjur/authn-oidc", kind: "policy" },
          annotations: { description: "this is my oidc authenticator" },
          data: {}
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when non-string type data is returned" do
      let(:authenticator_dict) do
        {
          type: "authn-oidc",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-oidc",
          annotations: { description: "this is my oidc authenticator" },
          variables: {
            ca_cert: "some-data".bytes
          }
        }
      end

      it "returns unchanged data" do
        json = authenticator.to_h
        expected_json = {
          type: "oidc",
          name: "auth1",
          branch: "conjur/authn-oidc",
          enabled: true,
          owner: { id: "conjur/authn-oidc", kind: "policy" },
          annotations: { description: "this is my oidc authenticator" },
          data: {
            ca_cert: "some-data".bytes
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when extra unknown variables exist in data" do
      let(:authenticator_dict) do
        {
          type: "authn-oidc",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-oidc",
          annotations: { description: "this is my oidc authenticator" },
          variables: {
            "unknown-key": "random_value",
            ca_cert: "CERT_DATA_1"
          }
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "oidc",
          name: "auth1",
          branch: "conjur/authn-oidc",
          enabled: true,
          owner: { id: "conjur/authn-oidc", kind: "policy" },
          annotations: { description: "this is my oidc authenticator" },
          data: {
            ca_cert: "CERT_DATA_1"
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "with all variables specified" do
      let(:args) do
        default_args.merge(
          {
            name: 'test',
            response_type: "code",
            redirect_uri: "https://test",
            token_ttl: 'PT60M',
            provider_scope: 'openid email profile'
          }
        )
      end

      let(:authenticator_dict) do
        {
          type: "authn-oidc",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-oidc",
          annotations: { description: "this is my oidc authenticator" },
          variables: args
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "oidc",
          name: "auth1",
          branch: "conjur/authn-oidc",
          enabled: true,
          owner: { id: "conjur/authn-oidc", kind: "policy" },
          annotations: { description: "this is my oidc authenticator" },
          data: {
            provider_uri: 'https://foo.bar.com/baz',
            client_id: 'client-id-123',
            client_secret: 'client-secret-123',
            claim_mapping: 'email',
            name: 'test',
            response_type: "code",
            redirect_uri: "https://test",
            token_ttl: 'PT60M',
            provider_scope: 'openid email profile'
          }
        }
        expect(json).to eq(expected_json)
      end
    end
  end
end
