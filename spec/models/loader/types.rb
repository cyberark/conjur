require 'spec_helper'

describe Loader::Types::User do
  let(:user) do
    user = Conjur::PolicyParser::Types::User.new
    user.id = resource_id
    user.account = 'default'
    Loader::Types.wrap(user, self)
  end

  describe '.verify' do
    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is true' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('true')
      end

      context 'when the user is loaded in the "my_sub_tree" policy' do
        let(:resource_id) { 'alice@my_sub_tree' }
#        it { expect { user.verify }.to raise_error(Exceptions::InvalidPolicyObject) }
      end

      context 'when the user is loaded in the "root" policy' do
        let(:resource_id) { 'alice' }
#        it { expect { user.verify }.to_not raise_error }
      end
    end
    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is false' do
      before do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('false')
      end

      context 'when the user is loaded in the "my_sub_tree" policy' do
        let(:resource_id) { 'alice@my_sub_tree' }
#        it { expect { user.verify }.to_not raise_error }
      end

      context 'when the user is loaded in the "root" policy' do
        let(:resource_id) { 'alice' }
#        it { expect { user.verify }.to_not raise_error }
      end
    end

    context 'when CONJUR_USERS_IN_ROOT_POLICY_ONLY is not set' do
      context 'when the user is loaded in the "my_sub_tree" policy' do
        let(:resource_id) { 'alice@my_sub_tree' }
#        it { expect { user.verify }.to_not raise_error }
      end

      context 'when the user is loaded in the "root" policy' do
        let(:resource_id) { 'alice' }
#        it { expect { user.verify }.to_not raise_error }
      end
    end
  end
end
