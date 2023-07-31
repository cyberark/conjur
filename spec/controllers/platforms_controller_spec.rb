# frozen_string_literal: true

require 'spec_helper'
DatabaseCleaner.strategy = :truncation

describe PlatformsController, type: :request do
  let(:url_resource) { "/resources/rspec" }
  before do
    init_slosilo_keys("rspec")
    # Load the base data/platforms policies into Conjur

    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => data_platforms_policy
      )
    )
    assert_response :success

  end

  let(:data_platforms_policy) do
    <<~POLICY
      - !policy
        id: data/platforms
        body: []
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }

  describe "#create" do
    context "when a user sends body with id only" do
      let(:payload_create_platforms_only_id) do
        <<~BODY
          { "id": "new-platform" }
        BODY
      end
      it 'returns bad request' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platforms_only_id,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when user sends body with id, max_ttl, type and data" do
      let(:payload_create_platforms_complete_input) do
        <<~BODY
          {
            "id": "aws-platform-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "access_key_secret": "my-key-secret"
            }
          }
        BODY
      end
      it 'it returns created' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platforms_complete_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq("aws-platform-1")
        expect(parsed_body["max_ttl"]).to eq(3000)
        expect(parsed_body["type"]).to eq("aws")
        expect(parsed_body["data"]["access_key_id"]).to eq("my-key-id")
        expect(parsed_body["data"]["access_key_secret"]).to eq("my-key-secret")
        expect(response.body).to include("\"created_at\"")
        expect(response.body).to include("\"modified_at\"")
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-1")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-1/delegation")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/aws-platform-1/delegation/consumers")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/aws-platform-1/delegation/secrets-creators")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-1/secrets")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/platforms/aws-platform-1/secrets/default")).not_to eq(nil)
      end
    end

    context "when user creates a policy with unsupported symbols in its name" do
      let(:payload_create_platforms_symbols_input) do
        <<~BODY
          {
            "id": "aws-platform-!@\#$%^*()[]",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "access_key_secret": "my-key-secret"
            }
          }
        BODY
      end
      it 'it returns created' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platforms_symbols_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("id param only supports alpha numeric characters and +-_")
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-!@#$%^*()[]")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-!@#$%^*()[]/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/aws-platform-!@#$%^*()[]/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/aws-platform-!@#$%^*()[]/delegation/secrets-creators")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/aws-platform-!@#$%^*()[]/secrets")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/platforms/aws-platform-!@#$%^*()[]/secrets/default")).to eq(nil)
      end
    end

    context "when user sends an empty body" do
      let(:payload_empty) do
        <<~BODY
          {
          }
        BODY
      end
      it 'it returns bad_request' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_empty,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when user sends an empty id" do
      let(:payload_blank_id) do
        <<~BODY
          {
            "id": ""
          }
        BODY
      end
      it "it returns bad_request" do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_blank_id,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
  
      end
    end

    context "when user sends a valid creation request but without permissions" do
      let(:payload_create_platforms_valid_input) do
        <<~BODY
          {
            "id": "valid-platform",
            "max_ttl": 1000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "access_key_secret": "my-key-secret"
            }
          }
        BODY
      end
      it 'returns forbidden' do
        post("/platforms/rspec",
             env: token_auth_header(role: alice_user).merge(
               'RAW_POST_DATA' => payload_create_platforms_valid_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :forbidden
        expect(response.body).to eq("")
      end
    end
  end

  describe "#delete" do
    context "when a user deletes a platform that does not exist" do
      it 'it returns not found' do
        delete("/platforms/rspec/non-existing-platform",
             env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Platform not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-platform\"}}}")
      end
    end

    context "when a user deletes an existing platform" do
      let(:payload_create_platform) do
        <<~BODY
          {
            "id": "my-new-aws-platform",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "access_key_secret": "a"
            }
          }
        BODY
      end
      it 'it is deleted successfully' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        delete("/platforms/rspec/my-new-aws-platform", env: token_auth_header(role: admin_user))
        assert_response :success
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/my-new-aws-platform")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/my-new-aws-platform/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/my-new-aws-platform/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:data/platforms/my-new-aws-platform/delegation/secrets-creators")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:data/platforms/my-new-aws-platform/secrets")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/platforms/my-new-aws-platform/secrets/default")).to eq(nil)
      end

      context "when a user deletes a non existing platform without permissions" do
        it 'it returns not found' do
          delete("/platforms/rspec/non-existing-platform", env: token_auth_header(role: alice_user))
          assert_response :not_found
        end
      end
    end

    context "when a user tries to delete a platform without the correct permissions" do
      let(:payload_create_platform) do
        <<~BODY
          {
            "id": "platform-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "access_key_secret": "a"
            }
          }
        BODY
      end
      it 'it returns not found' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        delete("/platforms/rspec/platform-1",
               env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Platform not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"platform-1\"}}}")
      end
    end
  end

  describe "#get" do
    context "when a user gets a platform that exists" do
      let(:payload_create_platform) do
        <<~BODY
          {
            "id": "platform-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "access_key_secret": "a"
            }
          }
        BODY
      end
      it 'the platform is returned' do

        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/platforms/rspec/platform-1",
             env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq("platform-1")
        expect(parsed_body["max_ttl"]).to eq(200)
        expect(parsed_body["type"]).to eq("aws")
        expect(parsed_body["data"]["access_key_id"]).to eq("a")
        expect(parsed_body["data"]["access_key_secret"]).to eq("a")
        expect(response.body).to include("\"created_at\"")
        expect(response.body).to include("\"modified_at\"")
      end
    end

    context "when a user gets a platform that does not exist" do
      it 'the response is not found' do
        get("/platforms/rspec/non-existing-platform",
            env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Platform not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-platform\"}}}")
      end
    end

    context "when a user that does not have permissions on platforms, gets a platform" do
      let(:payload_create_platform) do
        <<~BODY
          {
            "id": "platform-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "access_key_secret": "a"
            }
          }
        BODY
      end
      it 'the response is not found' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/platforms/rspec/platform-1",
            env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Platform not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"platform-1\"}}}")
      end
    end
  end

  describe "#list" do
    context "when a user lists the platforms" do
      let(:payload_create_platform_1) do
        <<~BODY
          {
            "id": "platform-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "access_key_secret": "a"
            }
          }
        BODY
      end
      let(:payload_create_platform_2) do
        <<~BODY
          {
            "id": "platform-2",
            "max_ttl": 300,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "access_key_secret": "aaa"
            }
          }
        BODY
      end
      it 'the platforms are returned' do
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform_1,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        post("/platforms/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_platform_2,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/platforms/rspec",
            env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["platforms"].length).to eq(2)

        expect(parsed_body["platforms"][0]["id"]).to eq("platform-1")
        expect(parsed_body["platforms"][0]["max_ttl"]).to eq(200)
        expect(parsed_body["platforms"][0]["type"]).to eq("aws")
        expect(parsed_body["platforms"][0]["data"]["access_key_id"]).to eq("a")
        expect(parsed_body["platforms"][0]["data"]["access_key_secret"]).to eq("a")

        expect(parsed_body["platforms"][1]["id"]).to eq("platform-2")
        expect(parsed_body["platforms"][1]["max_ttl"]).to eq(300)
        expect(parsed_body["platforms"][1]["type"]).to eq("aws")
        expect(parsed_body["platforms"][1]["data"]["access_key_id"]).to eq("aaa")
        expect(parsed_body["platforms"][1]["data"]["access_key_secret"]).to eq("aaa")
      end
    end

    context "when a user lists the platforms, and there are no platforms" do
      it 'the response is an object with an empty array' do
        get("/platforms/rspec",
            env: token_auth_header(role: admin_user))
        assert_response :success
        expect(response.body).to eq("{\"platforms\":[]}")
      end
    end

    context "when a user that does not have permissions to list platforms" do
      it 'the response is forbidden' do
        get("/platforms/rspec",
            env: token_auth_header(role: alice_user))
        assert_response :forbidden
        expect(response.body).to eq("")
      end
    end
  end
end
