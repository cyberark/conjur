# frozen_string_literal: true
require 'spec_helper'

describe SynchronizerCreationController, :type => :request do
  let(:super_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin_user') }
  let(:alice_user) { Role.find_or_create(role_id: 'rspec:user:alice') }

  let(:expected_event_object) { instance_double(Audit::Event::Policy) }
  let(:log_object) { instance_double(::Audit::Log::SyslogAdapter, log: expected_event_object) }

  let(:test_policy) do
    <<~POLICY
        - !user alice
        - !user admin_user
        - !policy
          id: synchronizer
          body:
            - !group synchronizer-hosts
            - !group synchronizer-installer-hosts
        - !group Conjur_Cloud_Admins
        - !grant
          role: !group Conjur_Cloud_Admins
          member: !user admin_user
    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    allow(Audit).to receive(:logger).and_return(log_object)

    init_slosilo_keys("rspec")
    
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
      # Correct audit is returned
      audit_message = "User rspec:user:admin_user successfully created new Synchronizer instance"
      verify_audit_message(audit_message)

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

  context "Synchronizer hosts get installer token" do
    subject{ SynchronizerCreationController.new }

    it "by admin user" do
      post("/synchronizer",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      resource_installer = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-installer-%/synchronizer-installer-host-%') }
      expect(resource_installer).not_to be_nil
      assert_response :created
      get("/synchronizer/installer-creds",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      assert_response :ok
      expect(response.body).not_to be_empty
    end

    it "by user" do
      post("/synchronizer",
           env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      resource_installer = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-installer-%/synchronizer-installer-host-%') }
      expect(resource_installer).not_to be_nil
      assert_response :created
      get("/synchronizer/installer-creds",
          env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      assert_response :forbidden
    end

    it "when synchronizer hosts never created" do
      # verify synchronizer hosts never created
      resource_host = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-%/synchronizer-host-%') }
      resource_installer = Resource.find { Sequel.like(:resource_id, 'rspec:host:synchronizer/synchronizer-installer-%/synchronizer-installer-host-%') }
      expect(resource_host).to be_nil
      expect(resource_installer).to be_nil
      # ask for a installer token
      get("/synchronizer/installer-creds",
          env: token_auth_header(role: admin_user).merge(v2_api_header)
      )
      assert_response :not_found
    end

  end
end
