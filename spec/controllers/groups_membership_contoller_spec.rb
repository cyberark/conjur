require 'spec_helper'
require './app/domain/util/static_account'

DatabaseCleaner.strategy = :truncation

describe GroupsMembershipController, type: :request do
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
      - !user rita

      - !group admins
      - !grant
         role: !group admins
         member:          
           - !user rita
      
      - !policy
        id: data
        owner: !group admins
        body:
        - !host host2
        - !host host3
        - !user user1    
        - !group testGroup    
        - !policy
          id: delegation
          body:
          - !host host1
          - !group consumers   
        - !grant
           role: !group delegation/consumers
           member:          
             - !host host3 

      - !permit
        resource: !policy data/delegation
        privilege: [ create, update ]
        role: !user alice

      - !permit
        resource: !policy data
        privilege: [ update, execute, read ]
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

  describe "Add member to group" do
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
        # correct header
        expect(response.headers['Content-Type'].include?(v2_api_header["Accept"])).to eq true
        # Host is a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq false
        # Correct audit is returned
        audit_message = "rspec:user:alice added membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        verify_audit_message(audit_message)
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end
    context "when resource id is sent without a leading /" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "data/host2"
        }
        BODY
      end
      it 'Host was added to group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        # correct response body
        expect(response.body).to eq("{\"kind\":\"host\",\"id\":\"data/host2\"}")
        # Trying adding the same host to the same group
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :conflict
        expect(response.body.include? "The 'data/host2' resource (kind='host') is already a member of the 'rspec:group:data/delegation/consumers' group").to eq true
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
      context "Adding user that is member of policy owner group" do
        let(:payload_add_members) do
          <<~BODY
        {
            "kind": "user",
            "id": "/rita"
        }
        BODY
        end
        it 'User was added to group' do
          post("/groups/data/delegation/consumers/members",
               env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end
    context "when no version header" do
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        # Trying adding the same host to the same group
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :conflict
        expect(response.body.include? "The '/data/host2' resource (kind='host') is already a member of the 'rspec:group:data/delegation/consumers' group").to eq true
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
             env: token_auth_header(role: bob_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        post("/groups/Conjur_Cloud_Users/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
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
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :bad_request
        expect(response.body.include? "The parameter received in the data is not valid. Allowed parameters: kind, id, branch, group_name").to eq true
      end
    end
  end

  describe "Remove member from group" do
    context "When host is member" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "host",
            "id": "/data/delegation/host1"
        }
        BODY
      end
      it 'Host was removed from group' do
        # Add member to group
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        # Correct response code
        assert_response :created
        # correct header
        expect(response.headers['Content-Type'].include?(v2_api_header["Accept"])).to eq true
        # Host is a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq false
        # Remove member from group
        delete("/groups/data/delegation/consumers/members/host/data/delegation/host1",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        # Correct response code
        assert_response :no_content
        # Host is not a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq true

        audit_message = "rspec:user:alice removed membership of rspec:host:data/delegation/host1 in rspec:group:data/delegation/consumers"
        verify_audit_message(audit_message)
      end
    end
    context "When user is a member" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "user",
            "id": "/alice"
        }
        BODY
      end
      it 'User was remove from group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        # Remove member from group
        delete("/groups/data/delegation/consumers/members/user/alice",
               env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        # Correct response code
        assert_response :no_content
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:user:alice").all.empty?).to eq true
      end
    end
    context "When group is a member" do
      let(:payload_add_members) do
        <<~BODY
        {
            "kind": "group",
            "id": "/data/testGroup"
        }
        BODY
      end
      it 'Group was removed from group' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: alice_user).merge(v2_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        # Remove member from group
        delete("/groups/data/delegation/consumers/members/group/data/testGroup",
               env: token_auth_header(role: alice_user).merge(v2_api_header)
        )
        # Correct response code
        assert_response :no_content
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:group:data/testGroup").all.empty?).to eq true
      end
    end
  end

  context "with input issues" do
    it 'Host was added not in group direct policy' do
      delete("/groups/data/delegation/consumers/members/host/data/host3",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :not_found
    end
    it 'When Group not exists' do
     delete("/groups/data/delegation/consumers2/members/host/data/delegation/host1",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :not_found
    end
    it 'When kind not exists' do
      delete("/groups/data/delegation/consumers/members/workload/data/delegation/host1",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :bad_request
    end
    it 'When no kind' do
      delete("/groups/data/delegation/consumers/members/data/delegation/host1",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :bad_request
    end
    it 'When no resource' do
      delete("/groups/data/delegation/consumers/members/host",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :bad_request
    end
    it 'When Resource not exists' do
      delete("/groups/data/delegation/consumers/members/host/data/delegation/hostNotExists",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :not_found
    end
    it 'When resource not a member in group' do
      delete("/groups/data/delegation/consumers/members/host/data/host2",
             env: token_auth_header(role: alice_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :not_found
    end
    it 'When user doesnt have permissions' do
      delete("/groups/data/delegation/consumers/members/host/data/delegation/host1",
             env: token_auth_header(role: bob_user).merge(v2_api_header)
      )
      # Correct response code
      assert_response :forbidden
    end
  end
end