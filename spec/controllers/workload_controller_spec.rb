# frozen_string_literal: true

require 'spec_helper'
DatabaseCleaner.strategy = :truncation

describe WorkloadController, type: :request do
  let(:test_value) { "testvalue" }
  let(:url_variable) { "/secrets/rspec/variable" }
  before do
    init_slosilo_keys("rspec")
    # Load the test policy into Conjur

    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        { 'RAW_POST_DATA' => test_policy }
      )
    )
    assert_response :success
    [
      "dev/secret1",
      "dev/secret2",
      "dev/secret3"
    ].each do |path|
      post("#{url_variable}/#{path}",
           env: token_auth_header(role: admin_user).merge(
             { 'RAW_POST_DATA' => "#{test_value}" }
           )
      )
      assert_response :success
    end

  end

  let(:test_policy) do
    <<~POLICY
      - !user alice
      - !policy
        id: test

      - !policy
        id: dev
        body:
        - !policy
          id: delegation
          body:
          - !group consumers
        - !variable secret1
        - !variable secret2
        - !variable secret3
      

      - !permit
        resource: !policy dev
        privilege: [ create, update ]
        role: !user alice
      
      - !permit
        resource: !policy test
        privilege: [ create, update ]
        role: !user alice
      

      - !permit
        resource: !variable dev/secret1
        privileges: [ read, execute ]
        roles: !group dev/delegation/consumers

    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }

  describe "#post" do
    context "when user send body with id only" do
      let(:payload_create_hosts) do
        <<~BODY
          { "id": "new-host_3" }
        BODY
      end
      it 'returns created' do
        init_slosilo_keys("rspec")
        # Testing that slosilo key was received from redis and not DB
        expect_any_instance_of(Slosilo::Adapters::SequelAdapter).not_to receive(:model)
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end

    context "when user send body with id from digits only" do
      let(:payload_create_hosts) do
        <<~BODY
          { "id": "333" }
        BODY
      end
      it 'returns created' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end
    end

    context "when user send body with annotations, safes" do
      let(:payload_create_hosts_annotations) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "safes": [
              "dev"
             ]
          }
        BODY
      end
      it 'returns created and can fetch secret' do
        post("/hosts/rspec/test",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts_annotations,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        host_role = Role.find(role_id: "rspec:host:test/new-host2")
        get("#{url_variable}/dev/secret1",
            env: token_auth_header(role: host_role))
        expect(response.body).to include("#{test_value}")
      end
      it 'returns not found invalid path' do
        post("/hosts/rspec/dev/invalid",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts_annotations,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
      end
    end

    context "duplicate will send conflict" do
      let(:payload_create_hosts_annotations) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "safes": [
              "dev"
             ]
          }
        BODY
      end
      it 'returns created and than conflict' do

        post("/hosts/rspec/test",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts_annotations,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        post("/hosts/rspec/test",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts_annotations,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :conflict
      end

    end

    context "workload name validation" do
      let(:payload_empty) do
        <<~BODY
          {
          }
        BODY
      end
      it 'empty returns unprocessable_entity' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_empty,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end
      let(:payload_blank_id) do
        <<~BODY
          {
            "id": ""
          }
        BODY
      end
      it "blank id return unprocessable_entity" do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_blank_id,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end
      let(:payload_short) do
        <<~BODY
          {
            "id": "ab"
          }
        BODY
      end
      it "short id return unprocessable_entity" do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_short,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end
      let(:payload_long) do
        <<~BODY
          {
            "id": "SuperExtremelyLongWorkloadName11111111111111111111111111111111111111111111111111"
          }
        BODY
      end
      it "long id return unprocessable_entity" do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_long,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end
      let(:payload_invalid) do
        <<~BODY
          {
            "id": "host+invalid"
          }
        BODY
      end
      it "invalid id return unprocessable_entity" do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_long,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end
      let(:payload) do
        <<~BODY
          {
            "id": "h/oSt_c1-s"
          }
        BODY
      end
      it "all valid chars are accepted" do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
      end

    end


    context "Wrong json object for safes" do
      let(:payload_invalid_safe) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "safes": "invalid"
          }
        BODY
      end
      it 'invalid group value should return 400' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_invalid_safe,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :unprocessable_entity
      end

    end
    context "Wrong json object for safes" do
      let(:payload_not_found_safe) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "safes": ["not-found"]
          }
        BODY
      end
      it 'not exist value of safe return 404' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_not_found_safe,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
      end

    end
  end

end
