# frozen_string_literal: true
require 'spec_helper'

describe EdgeConfigurationController, :type => :request do
  let(:account) { "rspec" }
  let(:admin_user_id) {"#{account}:user:admin_user"}
  let(:other_user_id) {"#{account}:user:other"}

  let(:validate_permissions) do
    "/agent/validate-permission/#{account}"
  end

  before do
    init_slosilo_keys(account)
    @other_user = Role.find_or_create(role_id: other_user_id)
    @admin_user = Role.find_or_create(role_id: admin_user_id)
  end

  context "Validate Permissions" do
    before do
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: admin_user_id, admin_option: false, ownership:false)
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Users")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Users", member_id: other_user_id, admin_option: false, ownership:false)
    end

    it "Conjur Admin user" do
      get("#{validate_permissions}", env: token_auth_header(role: @admin_user, is_user: true))
      expect(response.code).to eq("200")
    end

    it "Conjur user" do
      #Not admin
      get("#{validate_permissions}", env: token_auth_header(role: @other_user, is_user: true))
      expect(response.code).to eq("403")
    end
  end
end

