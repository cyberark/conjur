# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::ImplementedAuthenticators, type: :model do
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
end
