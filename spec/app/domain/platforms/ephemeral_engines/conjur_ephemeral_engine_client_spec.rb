# frozen_string_literal: true

require 'spec_helper'

class MockConjurEngineClient < ConjurEphemeralEngineClient
  def initialize(logger:, request_id:, http_client: nil)
    super(logger: logger, request_id: request_id, http_client: http_client)
  end

  def hash_keys_to_camel_case(hash, level = 0)
    super(hash, level)
  end
  
  def tenant_id
    super
  end
end

class MockHttpResponse
  def initialize(body, code)
    @body = body
    @code = code
  end
  
  attr_reader :code
  attr_reader :body
end

describe "Conjur ephemeral engine client validation" do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:mock_secret_result) do
    {
      "id" => "b549465d-140b-475e-ada3-bc50e07d09da",
      "ttl" => 1000,
      "data" => {
        "Credentials" => {
          "AccessKeyId" => "aws_key_id",
          "SecretAccessKey" => "aws_key_secret",
          "SessionToken" => "session_token",
          "Expiration" => "2023-07-03T15:28:23+00:00"
        },
        "FederatedUser" => {
          "FederatedUserId" => "238637036211:conjur,host,data.my-app", 
          "Arn" => "arn:aws:sts::238637036211:federated-user/conjur,host,data.my-app"
        },
        "PackedPolicySize" => 16
      }
    }
  end

  let(:mock_secret_error) do
    {
      "code" => "Error code",
      "message" => "Error message",
      "description" => "Error description"
    }
  end
  
  def mock_ephemeral_secrets_service(response_code)
    double('net_http_post').tap do |net_http_post|
      if response_code
        allow(net_http_post).to receive(:request)
          .and_return(MockHttpResponse.new(JSON.generate(mock_secret_error), response_code))
      else
        allow(net_http_post).to receive(:request)
          .and_return(MockHttpResponse.new(JSON.generate(mock_secret_result), 201))
      end
    end
  end
  
  context "when all input is valid" do
    it "then an ephemeral secret is returned" do
      platform_type = "aws"
      platform_method = "iam_federation"
      role_id = "conjur:host:data/my-host"
      platform_data = {
        max_ttl: 3000,
        data: {
          access_key_id: "my_key_id",
          access_key_secret: "my_secret_key"
        }
      }
      variable_data = {
        "max-ttl": 1000,
        "aws-region": "us-east-1",
        "policy": "my_inline_policy"
      }

      expect do
        MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(nil))
          .get_ephemeral_secret(platform_type, platform_method, role_id, platform_data, variable_data)
      end
        .to_not raise_error

      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(nil))
        .get_ephemeral_secret(platform_type, platform_method, role_id, platform_data, variable_data)

      expect(result).to eq(mock_secret_result)
    end
  end

  context "when there are failures from the ephemeral secrets service" do
    it "then the appropriate exception is raised" do
      platform_type = "aws"
      platform_method = "iam_federation"
      role_id = "conjur:host:data/my-host"
      platform_data = {
        data: {
          access_key_id: "my_key_id",
          access_key_secret: "my_secret_key"
        }
      }
      variable_data = {
        "max-ttl": 1000,
        "aws-region": "us-east-1",
        "policy": "my_inline_policy"
      }

      expect do
        MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service("400"))
          .get_ephemeral_secret(platform_type, platform_method, role_id, platform_data, variable_data)
      end.to raise_error(ApplicationController::BadRequest) do |error|
        expect(error.message).to eq("Failed to create the ephemeral secret. Code: Error code, Message: Error message, description: Error description")
      end

      expect do
        MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service("500"))
          .get_ephemeral_secret(platform_type, platform_method, role_id, platform_data, variable_data)
      end.to raise_error(ApplicationController::InternalServerError) do |error|
        expect(error.message).to eq("Failed to create the ephemeral secret. Code: Error code, Message: Error message, description: Error description")
      end
    end
  end

  context "when hash keys have hyphens, underscores or start with upper case" do
    let(:hash) do
      {
        "key-one": "value-one",
        "key_two": "value_two",
        "KeyThree": "ValueThree"
      }
    end
    
    it "then they are trimmed and turned to upper case" do
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {
        "keyOne" => "value-one",
        "keyTwo" => "value_two",
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
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {
        "keyOne" => "value-one",
        "keyTwo" => "value_two",
        "data" => {
          "subKeyOne" => "sub-key-value",
          "subKeyTwo" => "sub_key_value"
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
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {
        "keyOne" => "value-one",
        "keyTwo" => "value_two",
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

    it "then they are normalized into camel case" do
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {
        "keyOne" => "value-one",
        "keyTwo" => "value_two",
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

    it "then they are normalized into camel case" do
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {
        "keyOne#" => "value-one",
        "key%two" => "value_two",
        "keythre*e" => "valueThree"
      }

      expect(result).to eq(expected_result)
    end
  end

  context "when hash is empty" do
    let(:hash) {{}}

    it "then the result is empty as well" do
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil))
        .hash_keys_to_camel_case(hash)
      expected_result = {}

      expect(result).to eq(expected_result)
    end
  end

  context "when the hostname is parsed for the tenant ID" do
    it "then the tenant ID is successfully found" do
      ENV["HOSTNAME"] = "cnj-my_tenant_id-value1-value2"
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil)).tenant_id

      expect(result).to eq("my_tenant_id")
    end
  end

  context "when the hostname has an unexpected value" do
    it "then the tenant ID is empty" do
      ENV["HOSTNAME"] = "some_unexpected_value"
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil)).tenant_id

      expect(result).to eq("")
    end
  end

  context "when the hostname does not exist" do
    it "then the tenant ID is empty" do
      ENV["HOSTNAME"] = ""
      result = MockConjurEngineClient.new(logger: logger, request_id: "abc", http_client: mock_ephemeral_secrets_service(error: nil)).tenant_id

      expect(result).to eq("")
    end
  end
end
