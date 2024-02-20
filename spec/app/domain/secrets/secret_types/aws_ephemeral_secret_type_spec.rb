require 'spec_helper'

describe "AWS Ephemeral secret input validation" do
  context "when creating aws ephemeral secret with no region" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "federation-token")
      expect { Secrets::SecretTypes::AWSEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws ephemeral secret with empty region" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "federation-token",
                                                region: "")
      expect { Secrets::SecretTypes::AWSEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws ephemeral secret with wrong type region" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "federation-token",
                                                region: 5)
      expect { Secrets::SecretTypes::AWSEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws ephemeral secret with correct input" do
    it "then the input validation passes" do
      params = ActionController::Parameters.new(method: "federation-token",
                                                region: "us-east-1")
      expect { Secrets::SecretTypes::AWSEphemeralSecretType.new.input_validation(params)
      }.to_not raise_error
    end
  end
end
