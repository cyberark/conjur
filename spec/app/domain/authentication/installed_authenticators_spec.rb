# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::InstalledAuthenticators, type: :model do
  describe '.authenticators' do
    it 'returns merged V1 and V2 authenticators' do
      allow(Authentication::Util::V2::AuthenticatorLoader).to receive(:all).and_return({ v2: 'authenticator' })
      allow(described_class).to receive(:loaded_authenticators).and_return([double('AuthenticatorClass')])
      allow(described_class).to receive(:valid?).and_return(true)
      allow(described_class).to receive(:url_for).and_return('url')
      allow(described_class).to receive(:authenticator_instance).and_return('instance')

      result = described_class.authenticators('env')

      expect(result).to eq({ v2: 'authenticator', 'url' => 'instance' })
    end
  end

  describe '.login_authenticators' do
    it 'returns authenticators that provide login' do
      allow(described_class).to receive(:loaded_authenticators).and_return([double('AuthenticatorClass')])
      allow(described_class).to receive(:provides_login?).and_return(true)
      allow(described_class).to receive(:url_for).and_return('url')
      allow(described_class).to receive(:authenticator_instance).and_return('instance')

      result = described_class.login_authenticators('env')

      expect(result).to eq({ 'url' => 'instance' })
    end
  end

  describe '.configured_authenticators' do
    it 'returns configured authenticators including default' do
      resource_double = double('Resource')
      allow(Resource).to receive(:where).with(anything).and_return(resource_double)
      allow(resource_double).to receive(:where).with(anything).and_return(resource_double)
      allow(resource_double).to receive(:select_map).and_return(['conjur/authn-test'])

      result = described_class.configured_authenticators

      expect(result).to include('authn-test', 'authn')
    end
  end

  describe '.enabled_authenticators' do
    it 'returns enabled authenticators from environment and database' do
      allow(Rails.application.config.conjur_config).to receive(:authenticators).and_return(%w[authn-ldap authn-oidc])
      allow(described_class).to receive(:db_enabled_authenticators).and_return(['authn-oidc'])

      result = described_class.enabled_authenticators

      expect(result).to include('authn-ldap', 'authn-oidc')
    end
  end

  describe '.enabled_authenticators_default' do
    it 'returns authn if environment config is empty' do
      allow(Rails.application.config.conjur_config).to receive(:authenticators).and_return([])
      allow(described_class).to receive(:db_enabled_authenticators).and_return(['authn-oidc'])

      result = described_class.enabled_authenticators

      expect(result).to include('authn', 'authn-oidc')
    end
  end

  describe '.enabled_authenticators_str' do
    it 'returns enabled authenticators as a comma-separated string' do
      allow(described_class).to receive(:enabled_authenticators).and_return(['authn-ldap', 'authn-oidc'])

      result = described_class.enabled_authenticators_str

      expect(result).to eq('authn-ldap,authn-oidc')
    end
  end

  describe '.native_authenticators' do
    it 'returns native authenticators' do
      result = described_class.native_authenticators

      expect(result).to eq(['authn'])
    end
  end
end