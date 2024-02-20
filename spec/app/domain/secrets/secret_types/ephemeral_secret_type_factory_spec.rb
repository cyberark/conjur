require 'spec_helper'

describe "Ephemeral secret creation" do
  context "when creating ephemeral secret with no type" do
    it "then the creation fails" do
      expect { Secrets::SecretTypes::EphemeralSecretTypeFactory.new.create_ephemeral_secret_type(nil, nil)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating ephemeral secret with wrong type" do
    it "then the creation fails" do
      expect { Secrets::SecretTypes::EphemeralSecretTypeFactory.new.create_ephemeral_secret_type("gcp", nil)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws ephemeral secret with assume-role method" do
    it "then the creation succeeds" do
      params = ActionController::Parameters.new(
        region: "us-east-1",
        method: "assume-role")
      expect { Secrets::SecretTypes::EphemeralSecretTypeFactory.new.create_ephemeral_secret_type("aws", params)
      }.to_not raise_error
    end
  end
  context "when creating aws ephemeral secret with federation-token method" do
    it "then the creation succeeds" do
      params = ActionController::Parameters.new(
        region: "us-east-1",
        method: "federation-token")
      expect { Secrets::SecretTypes::EphemeralSecretTypeFactory.new.create_ephemeral_secret_type("aws", params)
      }.to_not raise_error
    end
  end
end