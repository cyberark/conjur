# frozen_string_literal: true
require 'spec_helper'

describe SynchronizerCreationController, :type => :request do
  let(:super_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin_user') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }
  let(:test_policy) do
    <<~POLICY
        - !user alice
        - !user admin_user
        - !policy
          id: synchronizer
          body:
            - !group synchronizer-hosts
            - !group synchronizer-installer-group
        - !group Conjur_Cloud_Admins
        - !grant
          role: !group Conjur_Cloud_Admins
          member: !user admin_user
    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    init_slosilo_keys("rspec")
    ENV['TENANT_ID'] ||= 'mytenant'
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: super_user).merge(
        { 'RAW_POST_DATA' => test_policy }
      )
    )
    assert_response :success
  end

  context "Synchronizer hosts creation" do
    subject{ SynchronizerCreationController.new }

    it "by admin user" do
      post("/synchronizer",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
           )
      resource_host = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-%/synchronizer-host-%') }
      resource_installer = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-installer-%/synchronizer-installer-host-%') }
      expect(resource_host).not_to be_nil
      expect(resource_installer).not_to be_nil
      assert_response :created
    end

    it "by unpermitted user" do
      post("/synchronizer",
           env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      assert_response :forbidden
    end

    it "when Synchronizer host already created" do
      # first creation
      post("/synchronizer",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      assert_response :created

      # second creation
      post("/synchronizer",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      assert_response :conflict
    end
  end
end

