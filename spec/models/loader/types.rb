require 'spec_helper'

describe Loader::Types do

  let(:new_user) {  Loader::Types::User.new(id: 'alice') }

  describe '.check_user_creation_allowed' do
    context "Check user creation verification" do

      it "should not allow user creation not under root" do
        allow(ENV).to receive(:[]).with('CONJUR_ALLOW_USER_CREATION').and_return('false')
        user = new_user()
        expect { new_user.check_user_creation_allowed(res_id: 'alice@my_sub_tree') }.to raise_error(Exceptions::InvalidPolicyObject)
      end
      it "should allow user creation not under root" do
        allow(ENV).to receive(:[]).with('CONJUR_ALLOW_USER_CREATION').and_return('true')
        user = new_user()
      end
    end
  end

end
