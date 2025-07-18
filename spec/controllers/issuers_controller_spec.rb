# frozen_string_literal: true

require 'spec_helper'
require 'time'

DatabaseCleaner.strategy = :truncation
CREATE_ISSUER_TIMEOUT = 10 # To test created_at
VALID_AWS_KEY = 'AKIAIOSFODNN7EXAMPLE'
VALID_AWS_SECRET = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
CHANGED_VALID_AWS_KEY = 'AKIAIOSFODNN7CHANGED'
CHANGED_VALID_AWS_SECRET = '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'
SENSITIVE_DATA_MASK = "*****"

describe IssuersController, type: :request do
  let(:url_resource) { "/resources/rspec" }

  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    # Load the users into Conjur
    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => data_users_policy
      )
    )
    assert_response :success

    allow_any_instance_of(Conjur::FeatureFlags::Features)
      .to receive(:enabled?)
      .and_call_original

    allow_any_instance_of(Conjur::FeatureFlags::Features)
      .to receive(:enabled?)
      .with(:dynamic_secrets)
      .and_return(dynamic_secrets_enabled)

    # Reload the initializer to take the feature flag settings and their impact
    # on routes.
    load Rails.root.join('config/initializers/feature_flags.rb')
    load Rails.root.join('config/routes.rb')
  end

  let(:dynamic_secrets_enabled) { true }

  let(:data_users_policy) do
    <<~POLICY
      - !user alice
      - !user bob
    POLICY
  end

  def load_issuers_base_policy
    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => data_issuers_policy
      )
    )
    assert_response :success
  end

  let(:data_issuers_policy) do
    <<~POLICY
      - !policy conjur/issuers
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:current_user_id) { 'rspec:user:admin' }
  let(:alice_user) { Role.find_or_create(role_id: alice_user_id) }
  let(:alice_user_id) { 'rspec:user:alice' }
  let(:bob_user) { Role.find_or_create(role_id: bob_user_id) }
  let(:bob_user_id) { 'rspec:user:bob' }

  describe "#update" do
    before do
      load_issuers_base_policy
    end

    describe "#aws" do
      context "when a user updates an issuer that does not exist" do
        payload_update_issuer = <<~BODY
          {
            "max_ttl": 200,
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        it 'it returns not found' do
          patch("/issuers/rspec/non-existing-issuer",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))
          assert_response :not_found
          expected_respones_body = <<-TEXT.squish
            {"error":{"code":"not_found","message":"Issuer not found","target":null,"details":{"code":"not_found","target":"id","message":"non-existing-issuer"}}}
          TEXT
          expect(response.body).to eq(expected_respones_body)
        end
      end

      context "when a user updates an issuer with invalid data" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "max_ttl": 2000,
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
              "invalid": "invalid"
            }
          }
        BODY

        it 'returns unprocessable entity and does not change the user' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          patch("/issuers/rspec/aws-issuer-1",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))

          assert_response :unprocessable_entity
          get("/issuers/rspec/aws-issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success

          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("aws-issuer-1")
          expect(parsed_body["max_ttl"]).to eq(3000)
          expect(parsed_body["type"]).to eq("aws")
          expect(parsed_body["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["data"]["secret_access_key"]).to eq(SENSITIVE_DATA_MASK)
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")
        end
      end

      context "when a user updates an issuer with ttl change only" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 2000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "max_ttl": 3000
          }
        BODY

        it 'updates the issuer' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          patch("/issuers/rspec/aws-issuer-1",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))

          assert_response :success
          get("/issuers/rspec/aws-issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success

          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("aws-issuer-1")
          expect(parsed_body["max_ttl"]).to eq(3000)
          expect(parsed_body["type"]).to eq("aws")
          expect(parsed_body["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["data"]["secret_access_key"]).to eq("*****")
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")
        end
      end

      context "when a user updates an issuer with data only" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "data": {
              "access_key_id": "AKIAIOSFODNN7CHANGED",
              "secret_access_key": "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"
            }
          }
        BODY

        it 'updates the issuer' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          patch("/issuers/rspec/aws-issuer-1",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))

          assert_response :success
          get("/issuers/rspec/aws-issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success

          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("aws-issuer-1")
          expect(parsed_body["max_ttl"]).to eq(3000)
          expect(parsed_body["type"]).to eq("aws")
          expect(parsed_body["data"]["access_key_id"]).to eq("AKIAIOSFODNN7CHANGED")
          expect(parsed_body["data"]["secret_access_key"]).to eq("*****")
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")
        end
      end

      context "when a user decrease TTL" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "max_ttl": 2000,
            "data": {
              "access_key_id": "#{CHANGED_VALID_AWS_KEY}",
              "secret_access_key": "#{CHANGED_VALID_AWS_SECRET}"
            }
          }
        BODY

        it 'returns bad request and does not change the TTL' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          patch("/issuers/rspec/aws-issuer-1",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))

          assert_response :bad_request
          expect(response.body).to eq("{\"error\":{\"code\":\"bad_request\",\"message\":\"The new max_ttl must be equal or higher than the current max_ttl\"}}")
        end
      end

      context "when a user change the acces key but no the secret" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "data": {
              "access_key_id": "#{CHANGED_VALID_AWS_KEY}"
            }
          }
        BODY

        it 'returns 422 and does not change the issuer' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          patch("/issuers/rspec/aws-issuer-1",
                env: token_auth_header(role: admin_user).merge(
                  'RAW_POST_DATA' => payload_update_issuer,
                  'CONTENT_TYPE' => "application/json"
                ))

          assert_response :unprocessable_entity
          expect(response.body).to eq("{\"error\":{\"code\":\"unprocessable_entity\",\"message\":\"secret_access_key is a required parameter and must be specified\"}}")
        end
      end

      context "when a user updates an issuer with valid data" do
        payload_create_issuers = <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY

        payload_update_issuer = <<~BODY
          {
            "max_ttl": 4000,
            "data": {
              "access_key_id": "#{CHANGED_VALID_AWS_KEY}",
              "secret_access_key": "#{CHANGED_VALID_AWS_SECRET}"
            }
          }
        BODY

        it 'returns ok and does change the user' do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers,
                 'CONTENT_TYPE' => "application/json"
               ))
          freeze_time do
            patch("/issuers/rspec/aws-issuer-1",
                  env: token_auth_header(role: admin_user).merge(
                    'RAW_POST_DATA' => payload_update_issuer,
                    'CONTENT_TYPE' => "application/json"
                  ))

            assert_response :ok
            parsed_body = JSON.parse(response.body)

            expect(parsed_body["id"]).to eq("aws-issuer-1")
            expect(parsed_body["max_ttl"]).to eq(4000)
            expect(parsed_body["type"]).to eq("aws")
            expect(parsed_body["data"]["access_key_id"]).to eq(CHANGED_VALID_AWS_KEY)
            expect(parsed_body["data"]["secret_access_key"]).to eq(SENSITIVE_DATA_MASK)
            expect(response.body).to include("\"created_at\"")
            created_time_from_body = Time.parse(parsed_body["created_at"])
            expect(created_time_from_body).to be_within(CREATE_ISSUER_TIMEOUT.second).of(Time.now)
            time_from_body = Time.parse(parsed_body["modified_at"])
            expect(time_from_body).to eq(Time.now)
          end
        end
      end
    end
  end

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

    context "when a user sends body without data but other non-valid field" do
      let(:payload_create_4_fields_without_data) do
        <<~BODY
          {
            "id": "aws-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "wrong": "wrong value"
          }
        BODY
      end

      it 'returns bad request' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_4_fields_without_data,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :bad_request
        expect(response.body).to eq("{\"error\":{\"code\":\"bad_request\",\"message\":\"data is a required parameter and must be specified\"}}")
      end
    end

    context "when user sends body with id, max_ttl, type and data" do
      let(:payload_create_issuers_complete_input) do
        <<~BODY
          {
            "id": "AWS-issuer-1",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY
      end

      it 'it returns created' do
        freeze_time do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuers_complete_input,
                 'CONTENT_TYPE' => "application/json"
               ))
          assert_response :created
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("AWS-issuer-1")
          expect(parsed_body["max_ttl"]).to eq(3000)
          expect(parsed_body["type"]).to eq("aws")
          expect(parsed_body["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["data"]["secret_access_key"]).to eq(SENSITIVE_DATA_MASK)
          expect(response.body).to include("\"created_at\"")
          created_time_from_body = Time.parse(parsed_body["created_at"])
          expect(created_time_from_body).to be_within(CREATE_ISSUER_TIMEOUT.second).of(Time.now)
          expect(response.body).to include("\"modified_at\"")
          time_from_body = Time.parse(parsed_body["modified_at"])
          expect(time_from_body).to eq(Time.now)
          expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/AWS-issuer-1")).not_to eq(nil)
          expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/AWS-issuer-1/delegation")).not_to eq(nil)
          expect(Resource.find(resource_id: "rspec:group:conjur/issuers/AWS-issuer-1/delegation/consumers")).not_to eq(nil)
        end
      end

      context 'when dynamic secrets feature is disabled' do
        let(:dynamic_secrets_enabled) { false }

        it 'returns not found' do
          expect do
            post(
              "/issuers/rspec",
              env: token_auth_header(role: admin_user).merge(
                'RAW_POST_DATA' => payload_create_issuers_complete_input,
                'CONTENT_TYPE' => "application/json"
              )
            )
          end.to raise_error(ActionController::RoutingError, /No route matches/)
        end
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
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
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

    context "when user creates an issuer with digits only in its name" do
      let(:payload_create_issuers_digits_input) do
        <<~BODY
          {
            "id": "555",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY
      end

      it 'it returns created' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_digits_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :created
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/555")).to_not eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/555/delegation")).to_not eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/555/delegation/consumers")).to_not eq(nil)
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
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY
      end

      let(:payload_create_ephemeral_variables) do
        <<~POLICY
          - !policy
            id: data/dynamic
            body:
            - !variable
              id: related-ephemeral-variable
              annotations:
                dynamic/issuer: my-new-aws-issuer
                dynamic/method: assume-role
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
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/related-ephemeral-variable")).to_not eq(nil)
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuer_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :conflict
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
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
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
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
              "unsupported_parameter": "aaa"
            }
          }
        BODY
      end

      it 'it returns unprocessable entity' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_symbols_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :unprocessable_entity
        expect(response.body).to eq("{\"error\":{\"code\":\"unprocessable_entity\",\"message\":\"invalid parameter received in data. Only access_key_id and secret_access_key are allowed\"}}")
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
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
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

    context "when a variable already exists that would associate with the issuer" do
      # For example, if restoring from a backup that already had variables with
      # the expectation annotations.
      let(:payload_create_issuers_valid_input) do
        <<~BODY
          {
            "id": "valid-issuer",
            "max_ttl": 3000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY
      end

      let(:variable_resource_id) do
        "rspec:variable:#{Issuer::DYNAMIC_VARIABLE_PREFIX}test"
      end

      before do
        Resource.create(
          resource_id: variable_resource_id,
          owner: current_user
        )

        Annotation.create(
          resource_id: variable_resource_id,
          name: "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer",
          value: "valid-issuer"
        )
      end

      it 'returns server error' do
        post("/issuers/rspec",
             env: token_auth_header(role: admin_user).merge(
               'RAW_POST_DATA' => payload_create_issuers_valid_input,
               'CONTENT_TYPE' => "application/json"
             ))
        assert_response :internal_server_error
        expect(response.body).to eq("")
      end
    end
  end

  describe "#delete" do
    let(:payload_create_issuer) do
      <<~BODY
        {
          "id": "my-new-aws-issuer",
          "max_ttl": 2000,
          "type": "aws",
          "data": {
            "access_key_id": "AKIAIOSFODNN7EXAMPLE",
            "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
          }
        }
      BODY
    end

    def create_issuer
      post(
          "/issuers/rspec",
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => payload_create_issuer,
            'CONTENT_TYPE' => "application/json"
          )
        )
        assert_response :created
    end

    before do
      load_issuers_base_policy
    end

    context "when a user deletes a issuer that does not exist" do
      it 'it returns not found' do
        delete("/issuers/rspec/non-existing-issuer",
               env: token_auth_header(role: admin_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"non-existing-issuer\"}}}")
      end
    end

    context "when a user deletes an existing issuer" do
      it 'it is deleted successfully' do
        create_issuer

        delete("/issuers/rspec/my-new-aws-issuer", env: token_auth_header(role: admin_user))
        assert_response :no_content
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Issuer.find(issuer_id: "my-new-aws-issuer")).to eq(nil)
        expect(Role.find(role_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Role.find(role_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Role.find(role_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(RoleMembership.find(role_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(RoleMembership.find(role_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(RoleMembership.find(role_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Permission.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer")).to eq(nil)
      end
    end

    context "when a user deletes a non existing issuer without permissions" do
      it 'it returns not found' do
        delete("/issuers/rspec/non-existing-issuer", env: token_auth_header(role: alice_user))
        assert_response :not_found
      end
    end

    context "when a user deletes an issuer that has variables assigned to it" do
      let(:payload_create_other_issuer) do
        <<~BODY
          {
            "id": "my-other-issuer",
            "max_ttl": 2000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            }
          }
        BODY
      end

      let(:payload_create_ephemeral_variables) do
        <<~POLICY
          - !policy
            id: data/dynamic
            body:
            - !variable
              id: related-ephemeral-variable
              annotations:
                dynamic/issuer: my-new-aws-issuer
                dynamic/method: assume-role
            - !variable
              id: unrelated-ephemeral-variable
              annotations:
                dynamic/issuer: my-other-issuer
                dynamic/method: assume-role
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
                dynamic/issuer: my-new-aws-issuer
                dynamic/method: assume-role
        POLICY
      end

      before do
        create_issuer
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
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/related-ephemeral-variable")).to_not eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/unrelated-ephemeral-variable")).to_not eq(nil)

        # Attempting to create a non-dynamic secret with the issuer annotation
        # isn't allowed and is enforced in policy validation.
        post(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => payload_create_non_ephemeral_variable
          )
        )
        assert_response :unprocessable_entity
        expect(Resource.find(resource_id: "rspec:variable:data/non-ephemeral-variable")).to eq(nil)
      end

      it 'deletes both issuer and related ephemeral variables successfully if requested' do
        delete("/issuers/rspec/my-new-aws-issuer?keep_secrets=false", env: token_auth_header(role: admin_user))
        assert_response :no_content

        # Issuer related resources are expected to be deleted, along with the ephemeral variables related to it
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/related-ephemeral-variable")).to eq(nil)

        # Non related ephemeral variables and non ephemeral variables are not deleted
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/unrelated-ephemeral-variable")).to_not eq(nil)

        # Non ephemeral secrets with an issuer annotation are never created to begin with
        expect(Resource.find(resource_id: "rspec:variable:data/non-ephemeral-variable")).to eq(nil)
      end

      it 'deletes issuer and delete related ephemeral variables by default' do
        delete("/issuers/rspec/my-new-aws-issuer", env: token_auth_header(role: admin_user))
        assert_response :no_content
        # Issuer related resources are expected to be deleted, along with the ephemeral variables related to it
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/related-ephemeral-variable")).to eq(nil)
      end

      it 'deletes issuer but keeps related ephemeral variables when flag is true' do
        delete("/issuers/rspec/my-new-aws-issuer?keep_secrets=true", env: token_auth_header(role: admin_user))
        assert_response :no_content
        # Issuer related resources are expected to be deleted, along with the ephemeral variables related to it
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:policy:conjur/issuers/my-new-aws-issuer/delegation")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:group:conjur/issuers/my-new-aws-issuer/delegation/consumers")).to eq(nil)
        expect(Resource.find(resource_id: "rspec:variable:data/dynamic/related-ephemeral-variable")).to_not eq(nil)
      end

      context "when a user deletes a non existing issuer without permissions" do
        it 'it returns not found' do
          delete("/issuers/rspec/non-existing-issuer", env: token_auth_header(role: alice_user))
          assert_response :not_found
        end
      end
    end

    context "when a user tries to delete a issuer without the correct permissions" do
      it 'it returns not found' do
        create_issuer

        delete("/issuers/rspec/my-new-aws-issuer",
               env: token_auth_header(role: alice_user))
        assert_response :not_found
        expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"my-new-aws-issuer\"}}}")
      end
    end

    context "when deletion fails with an unexpected error" do
      before do
        create_issuer

        # Attempting to delete variables for any issuer will trigger an
        # unexpected error.
        allow_any_instance_of(Issuer)
          .to receive(:delete_issuer_variables)
          .and_raise("Unexpected error")
      end

      it 'returns a server error' do
        delete(
          "/issuers/rspec/my-new-aws-issuer",
          env: token_auth_header(role: admin_user)
        )

        assert_response :internal_server_error
        expect(response.body).to eq("")
      end
    end
  end

  describe "#get" do
    before do
      load_issuers_base_policy
    end

    context "aws" do
      context "when a user gets a issuer that exists" do
        let(:payload_create_issuer) do
          <<~BODY
            {
              "id": "issuer-1",
              "max_ttl": 2000,
              "type": "aws",
              "data": {
                "access_key_id": "AKIAIOSFODNN7EXAMPLE",
                "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
              }
            }
          BODY
        end

        let(:issuer_membership) do
          <<~POLICY
            - !grant
              role: !group consumers
              member:
                - !user /alice
          POLICY
        end

        before do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuer,
                 'CONTENT_TYPE' => "application/json"
               ))
          assert_response :created
        end

        it 'the issuer is returned' do
          get("/issuers/rspec/issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("issuer-1")
          expect(parsed_body["max_ttl"]).to eq(2000)
          expect(parsed_body["type"]).to eq("aws")
          expect(parsed_body["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["data"]["secret_access_key"]).to eq(SENSITIVE_DATA_MASK)
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")
        end

        it 'wrong value for projection returns error' do
          get("/issuers/rspec/issuer-1?projection=not_supported",
              env: token_auth_header(role: admin_user))
          assert_response :unprocessable_entity
        end

        it 'no value for projection returns error' do
          get("/issuers/rspec/issuer-1?projection",
              env: token_auth_header(role: admin_user))
          assert_response :unprocessable_entity
        end

        it 'the minimum issuer is returned' do
          get("/issuers/rspec/issuer-1?projection=minimal",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body.length).to eq(1)
          expect(parsed_body["max_ttl"]).to eq(2000)
        end

        it 'get minimum with use permissions only' do
          patch(
            '/policies/rspec/policy/conjur/issuers/issuer-1/delegation',
            env: token_auth_header(role: admin_user).merge(
              { 'RAW_POST_DATA' => issuer_membership }
            )
          )
          assert_response :success

          get("/issuers/rspec/issuer-1?projection=minimal",
              env: token_auth_header(role: alice_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body.length).to eq(1)
          expect(parsed_body["max_ttl"]).to eq(2000)
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

      context "when the policy resource exists but the issuer record does not" do
        # For example, if the policy previously existed in a data backup
        before do
          Resource.create(
            resource_id: "rspec:policy:conjur/issuers/policy-only-issuer",
            owner: admin_user
          )
        end

        it 'returns not found' do
          get("/issuers/rspec/policy-only-issuer",
              env: token_auth_header(role: admin_user))
          assert_response :not_found
          expect(response.body).to eq("{\"error\":{\"code\":\"not_found\",\"message\":\"Issuer not found\",\"target\":null,\"details\":{\"code\":\"not_found\",\"target\":\"id\",\"message\":\"policy-only-issuer\"}}}")
        end
      end
    end

    context "when a user that does not have permissions on issuers, gets a issuer" do
      let(:payload_create_issuer) do
        <<~BODY
          {
            "id": "issuer-1",
            "max_ttl": 2000,
            "type": "aws",
            "data": {
              "access_key_id": "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
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
    before do
      load_issuers_base_policy
    end

    context "when a user lists the issuers with no issuers defined" do
      it 'empty list returned' do
        get("/issuers/rspec?sort=id",
            env: token_auth_header(role: admin_user))
        assert_response :success
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["issuers"].length).to eq(0)
      end
    end

    context "when a user lists the issuers" do
      context "aws" do
        let(:payload_create_issuer1) do
          <<~BODY
            {
              "id": "issuer-1",
              "max_ttl": 2000,
              "type": "aws",
              "data": {
                "access_key_id": "AKIAIOSFODNN7EXAMPLE",
                "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
              }
            }
          BODY
        end

        let(:payload_create_issuer2) do
          <<~BODY
            {
              "id": "issuer-2",
              "max_ttl": 3000,
              "type": "aws",
              "data": {
                "access_key_id": "AKIAIOSFODNN7EXAMPLE",
                "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
              }
            }
          BODY
        end

        before do
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuer2,
                 'CONTENT_TYPE' => "application/json"
               ))
          assert_response :created
          post("/issuers/rspec",
               env: token_auth_header(role: admin_user).merge(
                 'RAW_POST_DATA' => payload_create_issuer1,
                 'CONTENT_TYPE' => "application/json"
               ))
          assert_response :created
        end

        it 'the issuers are returned' do
          get("/issuers/rspec?sort=id",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["issuers"].length).to eq(2)

          expect(parsed_body["issuers"][0]["id"]).to eq("issuer-1")
          expect(parsed_body["issuers"][0]["max_ttl"]).to eq(2000)
          expect(parsed_body["issuers"][0]["type"]).to eq("aws")
          expect(parsed_body["issuers"][0]["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["issuers"][0]["data"]["secret_access_key"]).to eq("*****")
        end

        it 'the issuers are returned ordered asc' do
          get("/issuers/rspec?sort=id",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["issuers"].length).to eq(2)

          expect(parsed_body["issuers"][0]["id"]).to eq("issuer-1")
          expect(parsed_body["issuers"][0]["max_ttl"]).to eq(2000)
          expect(parsed_body["issuers"][0]["type"]).to eq("aws")
          expect(parsed_body["issuers"][0]["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["issuers"][0]["data"]["secret_access_key"]).to eq("*****")

          expect(parsed_body["issuers"][1]["id"]).to eq("issuer-2")
          expect(parsed_body["issuers"][1]["max_ttl"]).to eq(3000)
          expect(parsed_body["issuers"][1]["type"]).to eq("aws")
          expect(parsed_body["issuers"][1]["data"]["access_key_id"]).to eq("AKIAIOSFODNN7EXAMPLE")
          expect(parsed_body["issuers"][1]["data"]["secret_access_key"]).to eq("*****")
        end

        it 'the issuers are returned without ordered on not existent sort field' do
          get("/issuers/rspec?sort=name",
              env: token_auth_header(role: admin_user))
          assert_response :bad_request
        end

        it 'He can list the issuer and get it' do
          get("/issuers/rspec",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["issuers"].length).to eq(2)

          get("/issuers/rspec/issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("issuer-1")
          expect(parsed_body["max_ttl"]).to eq(2000)
          expect(parsed_body["type"]).to eq("aws")
          expect(response.body).to include("\"data\"")
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")

          get("/issuers/rspec/issuer-1?projection=minimal",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body.length).to eq(1)
          expect(parsed_body["max_ttl"]).to eq(2000)
          expect(response.body).to_not include("\"data\"")
        end

        it 'the issuers are returned without ordered on not existent sort field' do
          get("/issuers/rspec?sort=name",
              env: token_auth_header(role: admin_user))
          assert_response :bad_request
        end

        it 'He can list the issuer and get it' do
          get("/issuers/rspec",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["issuers"].length).to eq(2)

          get("/issuers/rspec/issuer-1",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body["id"]).to eq("issuer-1")
          expect(parsed_body["max_ttl"]).to eq(2000)
          expect(parsed_body["type"]).to eq("aws")
          expect(response.body).to include("\"data\"")
          expect(response.body).to include("\"created_at\"")
          expect(response.body).to include("\"modified_at\"")

          get("/issuers/rspec/issuer-1?projection=minimal",
              env: token_auth_header(role: admin_user))
          assert_response :success
          parsed_body = JSON.parse(response.body)
          expect(parsed_body.length).to eq(1)
          expect(parsed_body["max_ttl"]).to eq(2000)
          expect(response.body).to_not include("\"data\"")
        end
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
