# frozen_string_literal: true

require 'spec_helper'

describe Issuers::EphemeralEngines::ConjurDynamicEngineClient do
  subject do
    Issuers::EphemeralEngines::ConjurDynamicEngineClient.new(
      logger: logger,
      request_id: request_id,
      http_client: http_client_double
    )
  end

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:request_id) { 'rspec' }

  let(:http_client_double) do
    instance_double(Net::HTTP).tap do |http_client_double|
      allow(http_client_double)
        .to receive(:request)
        .and_return(response_double)
    end
  end

  let(:response_double) do
    instance_double(Net::HTTPResponse, code: response_code, body: response_body)
  end
  let(:response_code) { 200 }
  let(:response_body) { '' }

  describe '#dynamic_secret' do
    let(:response_body) { JSON.generate(mock_secret_result) }

    let(:mock_secret_result) do
      {
        "id" => "b549465d-140b-475e-ada3-bc50e07d09da",
        "ttl" => 1000,
        "data" => {
          "access_key_id" => "aws_key_id",
          "secret_access_key" => "secret_access_key",
          "session_token" => "session_token",
          "federated_user_id" => "238637036211:conjur,host,data.my-app",
          "federatedUserArn" => "arn:aws:sts::238637036211:federated-user/conjur,host,data.my-app"
        }
      }
    end

    let(:issuer_type) { "aws" }
    let(:issuer_method) { "iam_federation" }
    let(:role_id) { "conjur:host:data/my-host" }
    let(:issuer_data) do
      {
        max_ttl: 3000,
        data: {
          access_key_id: "my_key_id",
          secret_access_key: "my_secret_key"
        }
      }
    end

    let(:variable_data) do
      {
        "max-ttl": 1000,
        "aws-region": "us-east-1",
        "policy": "my_inline_policy"
      }
    end

    def dynamic_secret
      subject.dynamic_secret(
        issuer_type,
        issuer_method,
        role_id,
        issuer_data,
        variable_data
      )
    end

    context "when all input is valid" do
      it 'does not raise an error' do
        expect { dynamic_secret }.to_not raise_error
      end

      it 'matches the expected result' do
        expect(dynamic_secret).to eq(mock_secret_result.to_json)
      end
    end

    context "when there are failures from the ephemeral secrets service" do
      let(:response_code) { 422 }
      let(:response_body) { JSON.generate(mock_secret_error) }

      let(:mock_secret_error) do
        {
          "code" => "Error code",
          "message" => "Error message",
          "description" => "Error description"
        }
      end

      it "then the appropriate exception is raised" do
        expect do
          dynamic_secret
        end.to raise_error(ApplicationController::UnprocessableEntity) do |error|
          expect(error.message)
            .to eq(
              "Failed to create the dynamic secret. Code: Error code, Message: " \
              "Error message, description: Error description"
            )
        end
      end
    end

    context "when there are failures attempting to use the ephemeral secrets service" do
      before do
        allow(http_client_double)
          .to receive(:request)
          .and_raise("General failure")
      end

      it "then the appropriate exception is raised" do
        expect do
          dynamic_secret
        end.to raise_error(ApplicationController::InternalServerError) do |error|
          expect(error.message).to eq("General failure")
        end
      end
    end
  end

  describe '#normalize_hash_keys' do
    context "when hash keys have hyphens, underscores or start with upper case" do
      let(:hash) do
        {
          "key-one": "value-one",
          "key_two": "value_two",
          "KeyThree": "ValueThree"
        }
      end

      it "then they are trimmed and turned to upper case" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {
          "key_one" => "value-one",
          "key_two" => "value_two",
          "keythree" => "ValueThree"
        }

        expect(result).to eq(expected_result)
      end
    end

    context "when hash values are a hash as well" do
      let(:hash) do
        {
          "key-one": "value-one",
          "key_two": "value_two",
          "data": {
            "sub_key_one": "sub-key-value",
            "sub-key-two": "sub_key_value"
          }
        }
      end

      it "then the sub hash is transformed as well" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {
          "key_one" => "value-one",
          "key_two" => "value_two",
          "data" => {
            "sub_key_one" => "sub-key-value",
            "sub_key_two" => "sub_key_value"
          }
        }

        expect(result).to eq(expected_result)
      end
    end

    context "when hash keys are strings and not symbols" do
      let(:hash) do
        {
          "key-one" => "value-one",
          "key_two" => "value_two",
          "keyThree" => "valueThree"
        }
      end

      it "then they are transformed ok" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {
          "key_one" => "value-one",
          "key_two" => "value_two",
          "keythree" => "valueThree"
        }

        expect(result).to eq(expected_result)
      end
    end

    context "when hash keys have various upper and lower case letters" do
      let(:hash) do
        {
          "keY-oNE" => "value-one",
          "kEy_Two" => "value_two",
          "keyThRee" => "valueThree"
        }
      end

      it "then they are normalized" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {
          "key_one" => "value-one",
          "key_two" => "value_two",
          "keythree" => "valueThree"
        }

        expect(result).to eq(expected_result)
      end
    end

    context "when hash keys have various symbols" do
      let(:hash) do
        {
          "keY-oNE#" => "value-one",
          "kEy_%two" => "value_two",
          "keyThRe*e" => "valueThree"
        }
      end

      it "then they are normalized" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {
          "key_one#" => "value-one",
          "key_%two" => "value_two",
          "keythre*e" => "valueThree"
        }

        expect(result).to eq(expected_result)
      end
    end

    context "when hash is empty" do
      let(:hash) { {} }

      it "then the result is empty as well" do
        result = Issuers::EphemeralEngines::ConjurDynamicEngineClient.normalize_hash_keys(hash)

        expected_result = {}

        expect(result).to eq(expected_result)
      end
    end
  end
end
