require 'spec_helper'

describe Loader::Types do

  let(:new_user) {  Loader::Types::User.new(id: 'alice') }

  describe '.check_user_creation_allowed' do
    context "when the different values for CONJUR_USERS_IN_ROOT_POLICY_ONLY environment variable are provided" do

      it "should not allow user creation not under root" do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('true')
        user = new_user()
        expect { new_user.check_user_creation_allowed(resource_id: 'alice@my_sub_tree') }.to raise_error(Exceptions::InvalidPolicyObject)
      end
      it "should allow user creation not under root" do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('false')
        user = new_user()
        new_user.check_user_creation_allowed(resource_id: 'alice@my_sub_tree')
      end
      it "should allow user creation under root" do
        allow(ENV).to receive(:[]).with('CONJUR_USERS_IN_ROOT_POLICY_ONLY').and_return('true')
        user = new_user()
        new_user.check_user_creation_allowed(resource_id: 'alice')
      end
    end

  end

end
