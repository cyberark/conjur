# frozen_string_literal: true
require 'spec_helper'

describe InfoTenantController, :type => :request do
  let(:super_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
  let(:test_policy) do
    <<~POLICY
        - !user alice
        - !policy
          id: synchronizer
          body:
            - !group synchronizer-hosts
            - !group synchronizer-installer-hosts
    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    init_slosilo_keys("rspec")
  end

  context "Get tenant info" do
    subject{ InfoTenantController.new }
    it "by user positive scenrio" do
      put(
        '/policies/rspec/policy/root',
        env: token_auth_header(role: super_user).merge(
          { 'RAW_POST_DATA' => test_policy }
        )
      )
      assert_response :success
      get("/info",
           env: token_auth_header(role: alice_user).merge(v2_api_header)
           )
      assert_response :ok
      json_body = JSON.parse(response.body)
      expect(json_body).to include("is_pam_self_hosted"=> true)
      expect(json_body).to include("tenant_id"=> "mytenant")
    end

    it "by user - negative scenrio" do
      get("/info",
          env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      assert_response :ok
      json_body = JSON.parse(response.body)
      expect(json_body).to include("is_pam_self_hosted"=> false )
    end


  end
end
