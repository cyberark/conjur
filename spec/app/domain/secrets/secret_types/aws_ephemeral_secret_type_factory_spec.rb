require 'spec_helper'

describe "AWS Ephemeral secret creation" do
  context "when creating aws ephemeral secret with no type params" do
    it "then the creation fails" do
      expect { Secrets::SecretTypes::AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(nil)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws ephemeral secret with no method" do
    it "then the creation fails" do
      params = ActionController::Parameters.new(region: "us-east-1")
      expect { Secrets::SecretTypes::AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws ephemeral secret with not method" do
    it "then the creation fails" do
      params = ActionController::Parameters.new(
        method: "federation",
        region: "us-east-1")
      expect { Secrets::SecretTypes::AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws ephemeral secret with federation-token method" do
    it "then the creation succeeds" do
      params = ActionController::Parameters.new(
        region: "us-east-1",
        method: "federation-token")
      expect { Secrets::SecretTypes::AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(params)
      }.to_not raise_error
    end
  end
  context "when creating aws ephemeral secret with assume-role method" do
    it "then the creation succeeds" do
      params = ActionController::Parameters.new(
        region: "us-east-1",
        method: "assume-role")
      expect { Secrets::SecretTypes::AWSEphemeralSecretTypeFactory.new.create_aws_ephemeral_secret_type(params)
      }.to_not raise_error
    end
  end
end