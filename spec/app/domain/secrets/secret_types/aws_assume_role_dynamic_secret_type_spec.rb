require 'spec_helper'

describe "AWS Assume Role Dynamic secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 200
    }
  end
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Issuer).to receive(:where).with({:issuer_id=>"issuer1"}).and_return(issuer_object)
    allow(issuer_object).to receive(:first).and_return(issuer)
    allow(Resource).to receive(:[]).with("rspec:policy:data/ephemerals").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating aws ephemeral secret with empty region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "", role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws ephemeral secret with wrong type region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: 5, role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws ephemeral secret with empty inline_policy" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(inline_policy: "", role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws ephemeral secret with wrong type inline_policy" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(inline_policy: 5, role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws assume role ephemeral secret with no method params" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with empty role arn" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "us-east-1", role_arn: "")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with wrong type role arn" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "us-east-1", role_arn: 5)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws assume role ephemeral secret with no role arn" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws assume role ephemeral secret with ttl bigger then issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 220, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating aws assume role ephemeral secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
end

describe "AWS Ephemeral secret annotations creation" do
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
  end
  context "when creating aws ephemeral secret without inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(role_arn: "role", region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method:"assume-role", method_params: method_params)
      annotations = dynamic_secret.convert_fields_to_annotations(params)

      expect(annotations.length).to eq(5)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::EPHEMERAL_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::EPHEMERAL_TTL)).to eq(120)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::EPHEMERAL_METHOD)).to eq("assume-role")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::EPHEMERAL_ROLE_ARN)).to eq("role")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::EPHEMERAL_REGION)).to eq("us-east-1")
    end
  end
  context "when creating aws ephemeral secret with inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(role_arn: "role", region: "us-east-1", inline_policy:"policy")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer1", method:"assume-role", method_params: method_params)
      annotations = dynamic_secret.convert_fields_to_annotations(params)

      expect(annotations.length).to eq(6)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::EPHEMERAL_POLICY)).to eq("policy")
    end
  end
end