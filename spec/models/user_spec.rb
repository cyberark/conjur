# frozen_string_literal: true

require 'spec_helper'

describe User, :type => :model do

  describe "chec user creation restricted" do
    it "creation disallowed" do
      begin
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'false'
        user = User.new
        user.owner = 'pas-data';
        user.id = 'myuser1'
        user.verify()
      rescue Exceptions::InvalidPolicyObject => exc
        status='failure'
      ensure
        ENV['CONJUR_ALLOW_USER_CREATION'] = 'true'
      end
      expect(status).to eq('failure')
    end
  end


end
