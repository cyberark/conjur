# frozen_string_literal: true

require 'spec_helper'
DatabaseCleaner.strategy = :truncation

describe IssuersController, type: :request do
  let(:url_resource) { "/resources/rspec" }
  before do
    init_slosilo_keys("rspec")
    # Load the base conjur/issuers policies into Conjur

    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => data_issuers_policy
      )
    )
    assert_response :success

  end

  let(:data_issuers_policy) do
    <<~POLICY
      - !policy
        id: conjur/issuers
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
      let(:payload_create_issuers_only_id) do
        <<~BODY
          { "id": "new-issuer" }
        BODY
      end
      it 'returns bad request' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_only_id,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
      end
    end

    context "when user sends body with id, max_ttl, type and data" do
      let(:payload_create_issuers_complete_input) do
        <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      it 'it returns created' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_complete_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq("aws-issuer-1")
        expect(parsed_body["max_ttl"]).to eq(3000)
        expect(parsed_body["type"]).to eq("aws")
        expect(parsed_body["data"]["access_key_id"]).to eq("my-key-id")
        expect(parsed_body["data"]["secret_access_key"]).to eq("my-key-secret")
        expect(response.body).to include("\"created_at\"")
        expect(response.body).to include("\"modified_at\"")
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/aws-issuer-1")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/aws-issuer-1/delegation")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/aws-issuer-1/delegation/consumers")).not_to eq(nil)
      end
    end

    context "when user creates an issuer with unsupported symbols in its name" do
      let(:payload_create_issuers_symbols_input) do
        <<~BODY
          {
            "id": "aws-issuer-!@\#$%^*()[]",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      it 'it returns created' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_symbols_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["error"]["code"]).to eq("bad_request")
        expect(parsed_body["error"]["message"]).to eq("invalid 'id' parameter. Only the following characters are supported: A-Z, a-z, 0-9, +, -, and _")
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/aws-issuer-!@#$%^*()[]")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/aws-issuer-!@#$%^*()[]/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/aws-issuer-!@#$%^*()[]/delegation/consumers")).to eq(nil)
      end
    end

    context "when user tries to create an issuer but there are existing variables related to that id" do
      let(:payload_create_issuer_input) do
        <<~BODY
          {
            "id": "my-new-aws-issuer",
            "max_ttl": 2000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      let(:payload_create_ephemeral_variables) do
        <<~POLICY
          - !policy
            id: data/ephemerals
            body:
            - !variable
              id: related-ephemeral-variable
              annotations:
                ephemeral/issuer: my-new-aws-issuer
        POLICY
      end
      it 'it returns conflict' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).not_to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).not_to eq(nil)

        post(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => payload_create_ephemeral_variables
          )
        )
        assert_response :success
        expect(Resource.find(resource_id: "rspec:variable:data/ephemerals/related-ephemeral-variable")).to_not eq(nil)

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
        post("/issuers/rspec",
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
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_blank_id,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        expect(response.body).to eq("{\"error\":{\"code\":\"bad_request\",\"message\":\"issuer type is unsupported\"}}")

      end
    end

    context "when user specifies an unsupported parameter in the body" do
      let(:payload_create_issuers_symbols_input) do
        <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "unsupported_parameter": "aaa",
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      it 'it returns bad_request' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_symbols_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        expect(response.body).to eq("{\"error\":{\"code\":\"bad_request\",\"message\":\"invalid parameter received in the request body. Only id, type, max_ttl and data are allowed\"}}")
      end
    end

    context "when user specifies an unsupported parameter in the body data" do
      let(:payload_create_issuers_symbols_input) do
        <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret",
              "unsupported_parameter": "aaa"
            }
          }
        BODY
      end
      it 'it returns bad_request' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_symbols_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        expect(response.body).to eq("{\"error\":{\"code\":\"bad_request\",\"message\":\"invalid parameter received in data. Only access_key_id and secret_access_key are allowed\"}}")
      end
    end

    context "when user sends a valid creation request but without permissions" do
      let(:payload_create_issuers_valid_input) do
        <<~BODY
          {
            "id": "valid-issuer",
            "max_ttl": 1000,
            "type": "aws",
            "data": {
              "access_key_id": "my-key-id",
              "secret_access_key": "my-key-secret"
            }
          }
        BODY
      end
      it 'returns forbidden' do
        post("/issuers/rspec",
             env: token_auth_header(role: alice_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_valid_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :forbidden
        expect(response.body).to eq("")
      end
    end
  end

  describe "#delete" do
    context "when a user deletes a issuer that does not exist" do
      it 'it returns not found' do
        delete("/issuers/rspec/non-existing-issuer",
               env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-issuer\"}}}")
      end
    end

    context "when a user deletes an existing issuer" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "my-new-aws-issuer",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      it 'it is deleted successfully' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        delete("/issuers/rspec/my-new-aws-issuer", env: token_auth_header(role: admin_user))
        assert_response :success
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
      end

      context "when a user deletes a non existing issuer without permissions" do
        it 'it returns not found' do
          delete("/issuers/rspec/non-existing-issuer", env: token_auth_header(role: alice_user))
          assert_response :not_found
        end
      end
    end

    context "when a user deletes an issuer that has variables assigned to it" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "my-new-aws-issuer",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      let(:payload_create_other_issuer) do
        <<~BODY
          {
            "id": "my-other-issuer",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      let(:payload_create_ephemeral_variables) do
        <<~POLICY
          - !policy
            id: data/ephemerals
            body:
            - !variable
              id: related-ephemeral-variable
              annotations:
                ephemeral/issuer: my-new-aws-issuer
            - !variable
              id: unrelated-ephemeral-variable
              annotations:
                ephemeral/issuer: my-other-issuer
        POLICY
      end
      let(:payload_create_non_ephemeral_variable) do
        <<~POLICY
          - !policy
            id: data
            body:
            - !variable
              id: non-ephemeral-variable
              annotations:
                ephemeral/issuer: my-new-aws-issuer
        POLICY
      end
      it 'deletes both issuer and related ephemeral variables successfully' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer,
               'CONTENT_TYPE' => "application/json"
             ))
        post("/issuers/rspec",
              env: token_auth_header(role: admin_user).merge(
                'RAW_POST_DATA' => payload_create_other_issuer,
                'CONTENT_TYPE' => "application/json"
              ))
        assert_response :created
        post(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => payload_create_ephemeral_variables
          )
        )
        assert_response :success
        expect(Resource.find(resource_id: "rspec:variable:data/ephemerals/related-ephemeral-variable")).to_not eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/ephemerals/unrelated-ephemeral-variable")).to_not eq(nil)
        post(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => payload_create_non_ephemeral_variable
          )
        )
        assert_response :unprocessable_entity

        delete("/issuers/rspec/my-new-aws-issuer", env: token_auth_header(role: admin_user))
        assert_response :success
        # Issuer related resources are expected to be deleted, along with the ephemeral variables related to it
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/ephemerals/related-ephemeral-variable")).to eq(nil)

        # Non related ephemeral variables and non ephemeral variables are not deleted
        expect(Resource.find(resource_id: "rspec:variable:data/ephemerals/unrelated-ephemeral-variable")).to_not eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/non-ephemeral-variable")).to eq(nil)
      end

      context "when a user deletes a non existing issuer without permissions" do
        it 'it returns not found' do
          delete("/issuers/rspec/non-existing-issuer", env: token_auth_header(role: alice_user))
          assert_response :not_found
        end
      end
    end

    context "when a user tries to delete a issuer without the correct permissions" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "issuer-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      it 'it returns not found' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        delete("/issuers/rspec/issuer-1",
               env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"issuer-1\"}}}")
      end
    end
  end

  describe "#get" do
    context "when a user gets a issuer that exists" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "issuer-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      it 'the issuer is returned' do

        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/issuers/rspec/issuer-1",
            env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq("issuer-1")
        expect(parsed_body["max_ttl"]).to eq(200)
        expect(parsed_body["type"]).to eq("aws")
        expect(parsed_body["data"]["access_key_id"]).to eq("a")
        expect(parsed_body["data"]["secret_access_key"]).to eq("a")
        expect(response.body).to include("\"created_at\"")
        expect(response.body).to include("\"modified_at\"")
      end
    end

    context "when a user gets a issuer that does not exist" do
      it 'the response is not found' do
        get("/issuers/rspec/non-existing-issuer",
            env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-issuer\"}}}")
      end
    end

    context "when a user that does not have permissions on issuers, gets a issuer" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "issuer-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      it 'the response is not found' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/issuers/rspec/issuer-1",
            env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"issuer-1\"}}}")
      end
    end
  end

  describe "#list" do
    context "when a user lists the issuers" do
      let(:payload_create_issuer_1) do
        <<~BODY
          {
            "id": "issuer-1",
            "max_ttl": 200,
            "type": "aws",
            "data": {
              "access_key_id": "a",
              "secret_access_key": "a"
            }
          }
        BODY
      end
      let(:payload_create_issuer_2) do
        <<~BODY
          {
            "id": "issuer-2",
            "max_ttl": 300,
            "type": "aws",
            "data": {
              "access_key_id": "aaa",
              "secret_access_key": "aaa"
            }
          }
        BODY
      end
      it 'the issuers are returned' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer_1,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer_2,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created

        get("/issuers/rspec",
            env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["issuers"].length).to eq(2)

        expect(parsed_body["issuers"][0]["id"]).to eq("issuer-1")
        expect(parsed_body["issuers"][0]["max_ttl"]).to eq(200)
        expect(parsed_body["issuers"][0]["type"]).to eq("aws")

        expect(parsed_body["issuers"][1]["id"]).to eq("issuer-2")
        expect(parsed_body["issuers"][1]["max_ttl"]).to eq(300)
        expect(parsed_body["issuers"][1]["type"]).to eq("aws")
      end
    end

    context "when a user lists the issuers, and there are no issuers" do
      it 'the response is an object with an empty array' do
        get("/issuers/rspec",
            env: token_auth_header(role: admin_user))
        assert_response :success
        expect(response.body).to eq("{\"issuers\":[]}")
      end
    end

    context "when a user that does not have permissions to list issuers" do
      it 'the response is forbidden' do
        get("/issuers/rspec",
            env: token_auth_header(role: alice_user))
        assert_response :forbidden
        expect(response.body).to eq("")
      end
    end
  end
end
