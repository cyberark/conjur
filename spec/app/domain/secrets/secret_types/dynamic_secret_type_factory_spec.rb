require 'spec_helper'

describe "AWS Dynamic secret creation" do
  context "when creating aws dynamic secret with no method param" do
    it "then the creation fails" do
      expect { Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type(nil)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws dynamic secret with federation-token method" do
    it "then the creation succeeds" do
     expect(Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type("federation-token")
                                                          .instance_of?(Secrets::SecretTypes::AWSFederationTokenDynamicSecretType)).to eq(true)
    end
  end
  context "when creating aws dynamic secret with assume-role method" do
    it "then the creation succeeds" do
      expect(Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type("assume-role")
                                                           .instance_of?(Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType)).to eq(true)
    end
  end
end