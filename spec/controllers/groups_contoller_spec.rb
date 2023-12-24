require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe GroupsController, type: :request do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:bob_user_id) { 'rspec:user:bob' }
  let(:bob_user) { Role.find_or_create(role_id: bob_user_id) }

  let(:expected_event_object) { instance_double(Audit::Event::Policy) }
  let(:log_object) { instance_double(::Audit::Log::SyslogAdapter, log: expected_event_object) }

  let(:test_policy) do
    <<~POLICY
      - !user alice
      - !user bob
      
      - !policy
        id: data
        body:
        - !host host2
        - !user user1    
        - !group testGroup    
        - !policy
          id: delegation
          body:
          - !host host1
          - !group consumers     

      - !permit
        resource: !policy data/delegation
        privilege: [ create, update ]
        role: !user alice

      - !permit
        resource: !policy data/delegation
        privilege: [ create ]
        role: !user bob
    POLICY
  end

  before do
    StaticAccount.set_account('rspec')
    allow(Audit).to receive(:logger).and_return(log_object)

    init_slosilo_keys("rspec")
    # Load the test policy into Conjur
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        { 'RAW_POST_DATA' => test_policy }
      )
    )
    assert_response :success
  end

  describe "Add member from another branch to group" do
    context "when add host to group from same branch" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/delegation/host1"
        }
        BODY
      end
      it 'Host was added to group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct response body
        expect(response.body).to eq("{\"kind\":\"host\",\"id\":\"/data/delegation/host1\"}")
        # Host is a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq false
        # Correct audit is returned
        audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        message_found = false
        expect(log_object).to have_received(:log).at_least(:once) do |log_message|
          if log_message.to_s == audit_message
              message_found = true
          end
        end
        expect(message_found).to eq(true)
      end
    end
    context "when user with permissions add host to group" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2"
        }
        BODY
      end
      it 'Host was added to group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end
    context "when user with permissions add user to group" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "user",
            "id": "/alice"
        }
        BODY
      end
      it 'User was added to group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end
    context "when user with permissions add group to group" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "group",
            "id": "/data/testGroup"
        }
        BODY
      end
      it 'Group was added to group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end
  end

  describe "Add member with problems" do
    context "group that doesn't exists" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2"
        }
        BODY
      end
      it '404 error returned' do
        post("/groups/data/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
      end
    end
    context "Adding host to group that is already a member" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2"
        }
        BODY
      end
      it '409 error returned' do
        #Add the host to group
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        # Trying adding the same host to the same group
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :conflict
        expect(response.body.include? "Resource '/data/host2' of kind 'host' is already a member in group 'data/delegation/consumers'").to eq true
      end
    end
    context "User without update permissions on the group policy" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2"
        }
        BODY
      end
      it '403 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: bob_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :forbidden
      end
    end
    context "Adding to identity users group" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/Conjur_Cloud_Admins/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        post("/groups/Conjur_Cloud_Users/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
      end
    end
  end
  describe "Add member with invalid request" do
    context "Body not json" do
      let(:payload_add_members) do
        <<~BODY
        /data/host2
        BODY
      end
      it '400 error returned' do
        post("/groups/data/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
      end
    end
    context "Wrong member kind" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "workload",
            "id": "/data/host2"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "Member Kind parameter value is not valid").to eq true
      end
    end
    context "Missing member kind" do
      let(:payload_add_members) do
        <<~BODY
        {
            "id": "/data/host2"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "Missing required parameter: kind").to eq true
      end
    end
    context "Wrong member kind type" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": 5,
            "id": "/data/host2"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "The 'kind' parameter must be a String").to eq true
      end
    end
    context "Member kind is empty" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "",
            "id": "/data/host2"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "Missing required parameter: kind").to eq true
      end
    end
    context "Extra parameter" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/host2",
            "owner": "data"
        }
        BODY
      end
      it '400 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "Invalid parameter received in data. Only kind, id are allowed").to eq true
      end
    end
  end
end