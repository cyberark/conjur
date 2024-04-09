require 'spec_helper'

describe "AWS Federation Token Dynamic secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 200
    }
  end
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Issuer).to receive(:where).with({:issuer_id=>"issuer1"}).and_return(issuer_object)
    allow(issuer_object).to receive(:first).and_return(issuer)
    allow(Resource).to receive(:[]).with("rspec:policy:data/dynamic").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating aws federation token ephemeral secret with empty region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "", role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when creating aws federation token ephemeral secret with wrong type region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: 5, role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws federation token ephemeral secret with empty inline_policy" do
    it "then the input validation succeeds" do
      method_params = ActionController::Parameters.new(inline_policy: "", role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
  context "when creating aws federation token ephemeral secret with wrong type inline_policy" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(inline_policy: 5, role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating aws federation token ephemeral secret with no method params" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1")
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
  context "when creating aws federation token ephemeral secret with no issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws federation token ephemeral secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
end

describe "AWS Federation Token Dynamic replace secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 200
    }
  end
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Issuer).to receive(:where).with({:issuer_id=>"issuer1"}).and_return(issuer_object)
    allow(issuer_object).to receive(:first).and_return(issuer)
    allow(Resource).to receive(:[]).with("rspec:policy:data/dynamic").and_return("policy")
    allow(Resource).to receive(:[]).with("rspec:variable:data/dynamic/secret1").and_return("secret")
    $primary_schema = "public"
  end
  context "when replacing aws federation token dynamic secret with empty region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: "", role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when replacing aws federation token dynamic secret with wrong type region" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(region: 5, role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when replacing aws federation token dynamic secret with empty inline_policy" do
    it "then the input validation succeeds" do
      method_params = ActionController::Parameters.new(inline_policy: "", role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to_not raise_error
    end
  end
  context "when replacing aws federation token dynamic secret with wrong type inline_policy" do
    it "then the input validation fails" do
      method_params = ActionController::Parameters.new(inline_policy: 5, role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when replacing aws federation token dynamic secret with no method params" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1")
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to_not raise_error
    end
  end
  context "when replacing aws federation token dynamic secret with no issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when replacing aws federation token dynamic secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to_not raise_error
    end
  end
end

describe "AWS Ephemeral secret annotations creation" do
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
  end
  context "when creating aws ephemeral secret without inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method:"federation-token", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(4)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_TTL)).to eq(120)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_METHOD)).to eq("federation-token")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_REGION)).to eq("us-east-1")
    end
  end
  context "when creating aws ephemeral secret with inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(region: "us-east-1", inline_policy:"policy")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method:"federation-token", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(5)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_POLICY)).to eq("policy")
    end
  end
  context "when creating aws ephemeral secret without method params" do
    it "all annotations are created" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer1", method:"federation-token")
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(3)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_TTL)).to eq(120)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_METHOD)).to eq("federation-token")
    end
  end
end