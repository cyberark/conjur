require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe GroupMembershipsController, type: :request do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:bob_user_id) { 'rspec:user:bob' }
  let(:bob_user) { Role.find_or_create(role_id: bob_user_id) }

  let(:rita_user_id) { 'rspec:user:rita' }
  let(:rita_user) { Role.find_or_create(role_id: rita_user_id) }

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
        resource: !group data/delegation/consumers
        privilege: [ read ]
        role: !user alice

      - !permit
        resource: !user rita
        privilege: [ read ]
        role: !user alice

      - !permit
        resource: !host data/delegation/host1
        privilege: [ read ]
        role: !user alice

      - !permit
        resource: !host data/host3
        privilege: [ read ]
        role: !user alice

      - !permit
        resource: !host data/host2
        privilege: [ read ]
        role: !user alice

      - !permit
        resource: !policy data
        privilege: [ update, execute, read, create ]
        role: !user alice

      - !permit
        resource: !policy data/delegation
        privilege: [ update ]
        role: !user bob

      - !permit
        resource: !group data/delegation/consumers
        privilege: [ read ]
        role: !user bob
    POLICY
  end

  before do
    allow(Audit).to receive(:logger).and_return(log_object)

    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    # Load the test policy into Conjur
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        { RAW_POST_DATA: test_policy }
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
        post("/groups/rspec/data/delegation/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
            {
              'RAW_POST_DATA' => payload_add_members,
              'CONTENT_TYPE' => "application/json"
            }
          )
        )
        # Correct response code
        assert_response :created
        # correct response body
        expect(response.body).to eq("{\"kind\":\"host\",\"id\":\"data/delegation/host1\"}")
        # correct header
        expect(response.headers['Content-Type'].include?(v2_beta_api_header["Accept"])).to eq true
        # Host is a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq false
        # Correct audit is returned
        audit_message = "#{alice_user_id} successfully created membership data/delegation/consumers with URI path: '/groups/rspec/data/delegation/consumers/members' and JSON object: {\"kind\":\"host\",\"id\":\"/data/delegation/host1\"}"
        verify_audit_message(audit_message)
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
      it 'API call failed' do
        post("/groups/rspec/data/delegation/consumers/members",
          env: token_auth_header(role: alice_user).merge(
            {
              'RAW_POST_DATA' => payload_add_members,
              'CONTENT_TYPE' => "application/json"
            }
          )
        )
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["message"]).to eq("CONJ00194W The api belongs to v2 APIs but it missing the version \"#{V2RestController::API_V2_HEADER}\" in the Accept header")
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
        post("/groups/rspec/data/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
            {
              'RAW_POST_DATA' => payload_add_members,
              'CONTENT_TYPE' => "application/json"
            }
          )
        )
        assert_response :not_found
        audit_message = "rspec:user:alice failed to create membership data/consumers with URI path: '/groups/rspec/data/consumers/members' and JSON object: {\"kind\":\"host\",\"id\":\"/data/host2\"}: Group 'data/consumers' not found in account 'rspec'"
        verify_audit_message(audit_message)
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
        post("/groups/rspec/data/delegation/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
            {
              'RAW_POST_DATA' => payload_add_members,
              'CONTENT_TYPE' => "application/json"
            }
          )
        )
        assert_response :created
        # Trying adding the same host to the same group
        post("/groups/rspec/data/delegation/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
            {
                'RAW_POST_DATA' => payload_add_members,
                'CONTENT_TYPE' => "application/json"
            }
          )
        )
        assert_response :conflict
        expect(response.body.include? "'/data/host2' (kind='host') is already a member of 'rspec:group:data/delegation/consumers'").to eq true

        audit_message = "rspec:user:alice failed to create membership data/delegation/consumers with URI path: '/groups/rspec/data/delegation/consumers/members' and JSON object: {\"kind\":\"host\",\"id\":\"/data/host2\"}: CONJ00180W '/data/host2' (kind='host') is already a member of 'rspec:group:data/delegation/consumers'"
        verify_audit_message(audit_message)
      end
    end
    context "User without create permissions on the group policy" do
      let(:payload_add_members) do
        <<~BODY
          {
              "kind": "host",
              "id": "/data/host2"
          }
        BODY
      end
      it '404 error returned' do
        post("/groups/data/delegation/consumers/members",
             env: token_auth_header(role: bob_user).merge(v2_beta_api_header).merge(
               {
                 'RAW_POST_DATA' => payload_add_members,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
        audit_message = "rspec:user:bob failed to create membership delegation/consumers with URI path: '/groups/data/delegation/consumers/members' and JSON object: {\"kind\":\"host\",\"id\":\"/data/host2\"}: Branch 'delegation' not found in account 'data'"
        verify_audit_message(audit_message)
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
        post("/groups/rspec/data/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
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
        post("/groups/rspec/data/delegation/consumers/members",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header).merge(
            {
              'RAW_POST_DATA' => payload_add_members,
              'CONTENT_TYPE' => "application/json"
            }
          )
        )
        # Correct response code
        assert_response :created
        # correct header
        expect(response.headers['Content-Type'].include?(v2_beta_api_header["Accept"])).to eq true
        # Host is a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq false
        # Remove member from group
        delete("/groups/rspec/data/delegation/consumers/members/host/data/delegation/host1",
               env: token_auth_header(role: alice_user).merge(v2_beta_api_header)
        )
        # Correct response code
        assert_response :no_content
        # Host is not a member of group
        expect(RoleMembership.where(role_id: "rspec:group:data/delegation/consumers",member_id:"rspec:host:data/delegation/host1").all.empty?).to eq true

        # audit_message = "#{alice_user_id} successfully removed members to data/delegation/consumers with URI path: '/groups/data/delegation/consumers/members/host/data/delegation/host1'"
        # verify_audit_message(audit_message)
      end
    end

    context "When member was loaded to group by policy" do
      let(:add_member_policy) do
        <<~POLICY
          - !grant
             role: !group delegation/consumers
             member:
               - !host delegation/host1
        POLICY
      end
      it 'on root policy' do
        delete("/groups/rspec/data/delegation/consumers/members/host/data/host3",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header)
        )
        # Correct response code
        assert_response :success
      end
      it 'on not leaf policy policy' do
        # Load the policy into Conjur
        put(
          '/policies/rspec/policy/data',
          env: token_auth_header(role: admin_user).merge(
            { 'RAW_POST_DATA' => add_member_policy }
          )
        )
        assert_response :success
        delete("/groups/rspec/data/delegation/consumers/members/host/data/delegation/host1",
          env: token_auth_header(role: alice_user).merge(v2_beta_api_header)
        )
        # Correct response code
        assert_response :success
      end
    end
  end
end
