# frozen_string_literal: true

require 'spec_helper'
DatabaseCleaner.strategy = :truncation

describe LocksController, type: :request do
  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    # Load the base conjur/locks policies into Conjur

    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => data_locks_policy
      )
    )
    assert_response :success

  end

  let(:data_locks_policy) do
    <<~POLICY
      - !policy
        id: conjur/locks
        body:
        - !webservice my-lock
        - !webservice my-id$#@
        - !webservice non-existing-lock
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }

  describe "#create" do
    context "when a user creates a lock" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 5
          }
        BODY
      end
      it 'returns created' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
      end
    end

    context "when a user creates a lock with invalid id" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-id$#@",
            "owner": "my-lock-owner",
            "ttl": 5
          }
        BODY
      end
      it 'returns bad request' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when a user creates a lock with negative ttl" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": -1
          }
        BODY
      end
      it 'returns bad request' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when a user creates a lock with string ttl" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": "10"
          }
        BODY
      end
      it 'returns bad request' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when a user creates a lock with float ttl" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 1.5
          }
        BODY
      end
      it 'returns bad request' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when a user creates a lock without a webservice" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "non-existing-webservice-lock",
            "owner": "my-lock-owner",
            "ttl": 10
          }
        BODY
      end
      it 'returns not found' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :not_found
      end
    end

    context "when a user tries to create a lock that already exists" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 60
          }
        BODY
      end
      it 'returns conflict' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :conflict
      end
    end
  end

  describe "#delete" do
    context "when a user deletes a lock that does not exist" do
      it 'it returns not found' do
        delete("/locks/rspec/non-existing-lock",
               env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Lock not found\",\"target\":\"lock\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-lock\"}}}")
      end
    end

    context "when a user deletes a lock that does not have a webservice exist" do
      it 'it returns not found' do
        delete("/locks/rspec/non-existing-lock",
               env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Lock not found\",\"target\":\"lock\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-lock\"}}}")
      end
    end

    context "when a user deletes an existing lock" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 10
          }
        BODY
      end
      it 'it is deleted successfully' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        delete("/locks/rspec/my-lock", env: token_auth_header(role: admin_user))
        assert_response :success
      end

      context "when a user deletes a non existing lock without permissions" do
        it 'it returns not found' do
          delete("/locks/rspec/non-existing-lock", env: token_auth_header(role: alice_user))
          assert_response :not_found
          expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Webservice 'conjur/locks/non-existing-lock' not found in account 'rspec'\",\"target\":\"webservice\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"rspec:webservice:conjur/locks/non-existing-lock\"}}}")
        end
      end
    end
  end

  describe "#get" do
    context "when a user gets a lock that exists" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 10
          }
        BODY
      end
      it 'the lock is returned' do

        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/locks/rspec/my-lock",
            env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq("my-lock")
        expect(parsed_body["owner"]).to eq("my-lock-owner")
        expect(response.body).to include("\"created_at\"")
        expect(response.body).to include("\"modified_at\"")
        expect(response.body).to include("\"expires_at\"")
      end
    end

    context "when a user gets a lock that does not exist" do
      it 'the response is not found' do
        get("/locks/rspec/non-existing-lock",
            env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Lock not found\",\"target\":\"lock\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-lock\"}}}")
      end
    end

    context "when a user gets a lock that its webservice does not exist" do
      it 'the response is not found' do
        get("/locks/rspec/non-existing-webservice-lock",
            env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Webservice 'conjur/locks/non-existing-webservice-lock' not found in account 'rspec'\",\"target\":\"webservice\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"rspec:webservice:conjur/locks/non-existing-webservice-lock\"}}}")
      end
    end

    context "when a user that does not have permissions on lock webservice, gets a lock" do
      let(:payload_create_lock) do
        <<~BODY
          {
            "id": "my-lock",
            "owner": "my-lock-owner",
            "ttl": 10
          }
        BODY
      end
      it 'the response is not found' do
        post("/locks/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_lock,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/locks/rspec/my-lock",
            env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Webservice 'conjur/locks/my-lock' not found in account 'rspec'\",\"target\":\"webservice\",\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"rspec:webservice:conjur/locks/my-lock\"}}}")
      end
    end
  end
end