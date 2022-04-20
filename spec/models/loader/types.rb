require 'spec_helper'

describe Loader::Types::User do
  let(:user) do
    user = Conjur::PolicyParser::Types::User.new
    user.id = resource_id
    user.account = 'default'
    Loader::Types.wrap(user, self)
  end

  describe '.verify' do
    context 'when CONJUR_USERS_BY_ADMIN_ONLY is true' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_BY_ADMIN_ONLY').and_return('true')
      end

      context 'when the user is loaded be admin user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'admin') }.to_not raise_error }
      end

      context 'when the user is loaded by tina user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'tina') }.to raise_error(Exceptions::InvalidPolicyObject) }
      end
    end
    context 'when CONJUR_USERS_BY_ADMIN_ONLY is false' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_BY_ADMIN_ONLY').and_return('false')
      end

      context 'when the user is loaded by admin user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'admin') }.to_not raise_error }
      end

      context 'when the user is loaded by tina user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'tina') }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_BY_ADMIN_ONLY is not set' do
      context 'when the user is loaded by admin user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'admin') }.to_not raise_error }
      end

      context 'when the user is loaded by tina user' do
        let(:resource_id) { 'alice' }
        it { expect { user.check_user_creation_allowed(resource_id: 'alice', user_id: 'tina') }.to_not raise_error }
      end
    end
  end
end
