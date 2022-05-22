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
