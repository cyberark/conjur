require 'spec_helper'

describe Loader::Types::User do
  let(:user) do
    role = Conjur::PolicyParser::Types::Role.new
    role.id = role_id
    role.kind = role_kind
    role.account = 'default'
    user = Conjur::PolicyParser::Types::User.new
    user.id = resource_id
    user.account = 'default'
    user.owner = role
    Loader::Types.wrap(user, self)
  end

  describe '.verify' do
    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is true' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('true')
      end

      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when non admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'myuser' }
        it { expect { user.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is false' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('false')
      end

      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when non admin user creating user in the "root" policy' do
        let(:role_kind) { 'user' }
        let(:resource_id) { 'alice@cyberark' }
        let(:role_id) { 'myuser' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:role_kind) { 'user' }
        let(:resource_id) { 'alice@cyberark' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is not set' do
      context 'when creating user in the "admin" sub-policy' do
        let(:resource_id) { 'alice@admin' }
        let(:role_kind) { 'policy' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end

      context 'when admin user creating user in the "root" policy' do
        let(:resource_id) { 'alice@cyberark' }
        let(:role_kind) { 'user' }
        let(:role_id) { 'admin' }
        it { expect { user.verify }.to_not raise_error }
      end
    end
  end
end

describe Loader::Types::Host do
  let(:host) do
    host = Conjur::PolicyParser::Types::Host.new
    host.id = resource_id
    if api_key != ''
      host.annotations =  { "authn/api-key" => api_key }
    end
    Loader::Types.wrap(host, self)
  end

  describe '.verify' do
    context 'when CONJUR_AUTHN_API_KEY_DEFAULT is true' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_AUTHN_API_KEY_DEFAULT').and_return('true')
        Rails.application.config.conjur_config.authn_api_key_default = true
      end

      context 'when creating host with api-key annotation true' do
        let(:resource_id) { 'myhost@admin' }
        let(:api_key) { true }
        it { expect { host.verify }.to_not raise_error }
      end

      context 'when creating host with api-key annotation false' do
        let(:resource_id) { 'myhost@cyberark' }
        let(:api_key) { false }
        it { expect { host.verify }.to_not raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'myhost@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to_not raise_error(Exceptions::InvalidPolicyObject) }
      end
    end

    context 'when CONJUR_AUTHN_API_KEY_DEFAULT is false' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_AUTHN_API_KEY_DEFAULT').and_return('false')
        Rails.application.config.conjur_config.authn_api_key_default = false
      end

      context 'when creating host with api-key annotation true' do
        let(:resource_id) { 'myhost@admin' }
        let(:api_key) { true }
        it { expect { host.verify }.to_not raise_error }
      end

      context 'when creating host with api-key annotation false' do
        let(:resource_id) { 'alice@cyberark' }
        let(:api_key) { false }
        it { expect { host.verify }.to raise_error }
      end

      context 'when creating host without api-key annotation' do
        let(:resource_id) { 'alice@cyberark' }
        let(:api_key) { '' }
        it { expect { host.verify }.to raise_error }
      end
    end

  end
end
