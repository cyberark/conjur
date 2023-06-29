# frozen_string_literal: true

require 'spec_helper'
DatabaseCleaner.strategy = :truncation

describe HostsController, type: :request do
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
        id: dev
        body:
        - !group developers
        - !layer layers
        - !variable secret1
        - !variable secret2
        - !variable secret3
     
      - !grant
        role: !group dev/developers
        member: !user alice

      - !permit
        resource: !policy dev
        privilege: [ create ]
        role: !user alice
      
      - !permit
        resource: !variable dev/secret1
        privileges: [ read, execute ]
        roles: !group dev/developers

      - !permit
        resource: !variable dev/secret2
        privileges: [ read, execute ]
        roles: !group dev/developers

      - !permit
        resource: !variable dev/secret3
        privileges: [ read, execute ]
        roles: !group dev/developers
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
          { "id": "new-host" }
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

    context "when user send body with annotations, groups and layers" do
      let(:payload_create_hosts_annotations) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "groups": [
              "developers"
             ],
            "layers": [
              "layers"
             ]
          }
        BODY
      end
      it 'returns created and can fetch secret' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_create_hosts_annotations,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :created
        host_role = Role.find(role_id: "rspec:host:dev/new-host2")
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

    context "empty id or body" do
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
    end

    context "Invalid values for groups and layers" do
      let(:payload_invalid_group) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "groups": [
              "invalid"
             ]
          }
        BODY
      end
      it 'invalid group value should return 400' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_invalid_group,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
      end
      let(:payload_invalid_layer) do
        <<~BODY
            {
            "id": "new-host2",
            "annotations": {
            "description": "describe"
            },
            "layers": [
              "invalid"
             ]
          }
        BODY
      end
      it 'invalid layer value should return 400' do
        post("/hosts/rspec/dev",
             env: token_auth_header(role: alice_user).merge(
               {
                 'RAW_POST_DATA' => payload_invalid_layer,
                 'CONTENT_TYPE' => "application/json"
               }
             )
        )
        assert_response :not_found
      end
    end
  end

end
