require 'spec_helper'

describe Loader::Types do
  context "Check user creation verification" do
    def new_user()
      Loader::Types::User.new(
        id: 'alice')
    end
    it "should not allow user creation not under root" do
      ENV['CONJUR_ALLOW_USER_CREATION'] = 'false'
      user = new_user()
      status='success'
      begin
        user.check_user_creation_allowed(res_id: 'alice@my_sub_tree')
      rescue Exceptions::InvalidPolicyObject => exc
        status='failure'
      ensure
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'true'
      end
      expect(status).to eq('failure')
    end
    it "should allow user creation not under root" do
      ENV['CONJUR_ALLOW_USER_CREATION'] = 'true'
      user = new_user()
      status='success'
      begin
        user.check_user_creation_allowed(res_id: 'alice@my_sub_tree')
      rescue Exceptions::InvalidPolicyObject => exc
        status='failure'
      ensure
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'true'
      end
      expect(status).to eq('success')
    end
  end

end
