require 'spec_helper'

describe "AWS Ephemeral secret annotations creation" do
  context "when creating aws ephemeral secret without inline policy" do
    it "all annotations are created" do
      ephemeral_params = ActionController::Parameters.new(method: "federation-token",
                                                region: "us-east-1"
      )
      ephemeral = ActionController::Parameters.new(type: "aws", issuer: "issuer1", ttl: 120, type_params: ephemeral_params)
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      secret_type = Secrets::SecretTypes::EphemeralSecretType.new
      secret_type.initialize_ephemeral_type("aws", ephemeral_params)
      annotations = secret_type.convert_fields_to_annotations(params)
      expect(annotations.length).to eq(5)
      expect(annotations['conjur/kind']).to eq("ephemeral")
      expect(annotations[Secrets::SecretTypes::EphemeralSecretType::EPHEMERAL_ISSUER]).to eq("issuer1")
      expect(annotations[Secrets::SecretTypes::EphemeralSecretType::EPHEMERAL_TTL]).to eq(120)
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_METHOD]).to eq("federation-token")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_REGION]).to eq("us-east-1")
      expect(annotations.key?(Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_POLICY)).to eq(false)
    end
  end
  context "when creating aws ephemeral secret with inline policy" do
    it "all annotations are created" do
      ephemeral_params = ActionController::Parameters.new(method: "assume-role",
                                                          region: "us-east-1",
                                                          inline_policy: "{}",
                                                          method_params:  ActionController::Parameters.new(role_arn: "role")
      )
      ephemeral = ActionController::Parameters.new(type: "aws", issuer: "issuer1", ttl: 120, type_params: ephemeral_params)
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      secret_type = Secrets::SecretTypes::EphemeralSecretType.new
      secret_type.initialize_ephemeral_type("aws", ephemeral_params)
      annotations = secret_type.convert_fields_to_annotations(params)
      expect(annotations.length).to eq(7)
      expect(annotations['conjur/kind']).to eq("ephemeral")
      expect(annotations[Secrets::SecretTypes::EphemeralSecretType::EPHEMERAL_ISSUER]).to eq("issuer1")
      expect(annotations[Secrets::SecretTypes::EphemeralSecretType::EPHEMERAL_TTL]).to eq(120)
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_METHOD]).to eq("assume-role")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_REGION]).to eq("us-east-1")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_POLICY]).to eq("{}")
      expect(annotations[Secrets::SecretTypes::AWSAssumeRoleEphemeralSecretType::EPHEMERAL_ROLE_ARN]).to eq("role")
    end
  end
  context "when creating assume role aws ephemeral secret" do
    it "all annotations are created" do
      ephemeral_params = ActionController::Parameters.new(method: "assume-role",
                                                          region: "us-east-1",
                                                          inline_policy: "{}",
                                                          method_params:  ActionController::Parameters.new(role_arn: "role")
      )
      secret_type = Secrets::SecretTypes::AWSAssumeRoleEphemeralSecretType.new
      Secrets::SecretTypes::EphemeralSecretType.new.initialize_ephemeral_type("aws", ephemeral_params)
      annotations = secret_type.convert_fields_to_annotations(ephemeral_params)
      expect(annotations.length).to eq(4)
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_METHOD]).to eq("assume-role")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_REGION]).to eq("us-east-1")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_POLICY]).to eq("{}")
      expect(annotations[Secrets::SecretTypes::AWSAssumeRoleEphemeralSecretType::EPHEMERAL_ROLE_ARN]).to eq("role")
    end
  end
  context "when creating federation token aws ephemeral secret" do
    it "all annotations are created" do
      ephemeral_params = ActionController::Parameters.new(method: "federation-token",
                                                          region: "us-east-1"
      )
      secret_type = Secrets::SecretTypes::AWSEFederationTokenEphemeralSecretType.new
      Secrets::SecretTypes::EphemeralSecretType.new.initialize_ephemeral_type("aws", ephemeral_params)
      annotations = secret_type.convert_fields_to_annotations(ephemeral_params)
      expect(annotations.length).to eq(2)
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_METHOD]).to eq("federation-token")
      expect(annotations[Secrets::SecretTypes::AWSEphemeralSecretType::EPHEMERAL_REGION]).to eq("us-east-1")
    end
  end
end
