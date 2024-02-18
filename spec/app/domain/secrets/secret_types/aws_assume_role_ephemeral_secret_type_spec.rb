require 'spec_helper'

describe "AWS Assume Role Ephemeral secret input validation" do
  context "when creating aws assume role ephemeral secret with no region" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "assume-role")
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with no method params" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "assume-role",
                                                region: "us-east-1"
      )
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with empty role arn" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "assume-role",
                                                region: "us-east-1",
                                                method_params:  ActionController::Parameters.new(role_arn: "")
      )
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with wrong type role arn" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "assume-role",
                                                region: "us-east-1",
                                                method_params:  ActionController::Parameters.new(role_arn: 5)
      )
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws assume role ephemeral secret with no role arn" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(method: "assume-role",
                                                region: "us-east-1",
                                                method_params:  ActionController::Parameters.new()
      )
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with correct input" do
    it "then the input validation passes" do
      params = ActionController::Parameters.new(method: "assume-role",
                                                region: "us-east-1",
                                                method_params:  ActionController::Parameters.new(role_arn: "role")
      )
      expect { Secrets::SecretTypes::AWSRoleEphemeralSecretType.new.input_validation(params)
      }.to_not raise_error
    end
  end
end
