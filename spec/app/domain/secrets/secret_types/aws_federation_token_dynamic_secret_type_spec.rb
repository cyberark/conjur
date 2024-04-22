require 'spec_helper'

describe "AWS Federation Token Dynamic secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 2000,
      issuer_type: "aws"
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
  context "when validating create request" do
    let(:params) do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name", region: "us-east-1", inline_policy: "policy")
      ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params, method: "assume-role")
    end

    it "correct validators are being called for each field" do
      expect(dynamic_secret).to receive(:validate_field_type).with(:region,{type: String,value: "us-east-1"})
      expect(dynamic_secret).to receive(:validate_region).with(:region,{type: String,value: "us-east-1"})

      expect(dynamic_secret).to receive(:validate_field_type).with(:inline_policy,{type: String,value: "policy"})

      dynamic_secret.send(:input_validation, params)
    end
  end
  context "when creating aws federation token ephemeral secret with no method params" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method: "federation-token")
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
  context "when creating aws federation token ephemeral secret with no issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, method_params: method_params, method: "assume-role")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating aws federation token ephemeral secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params, method: "assume-role")
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
      max_ttl: 2000,
      issuer_type: "aws"
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
  context "when validating create request" do
    let(:params) do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name", region: "us-east-1", inline_policy: "policy")
      ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params, method: "assume-role")
    end

    it "correct validators are being called for each field" do
      expect(dynamic_secret).to receive(:validate_field_type).with(:region,{type: String,value: "us-east-1"})
      expect(dynamic_secret).to receive(:validate_region).with(:region,{type: String,value: "us-east-1"})

      expect(dynamic_secret).to receive(:validate_field_type).with(:inline_policy,{type: String,value: "policy"})

      dynamic_secret.send(:input_validation, params)
    end
  end
  context "when replacing aws federation token dynamic secret with no method params" do
    it "then the input validation succeeds" do
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 1200, issuer: "issuer1", method: "federation-token")
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to_not raise_error
    end
  end
  context "when replacing aws federation token dynamic secret with no issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "role")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 1200, method_params: method_params, method: "assume-role")
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when replacing aws federation token dynamic secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(region: "us-east-1")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 1200, issuer: "issuer1", method_params: method_params, method: "assume-role")
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
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method:"federation-token", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(4)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_TTL)).to eq(1200)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_METHOD)).to eq("federation-token")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_REGION)).to eq("us-east-1")
    end
  end
  context "when creating aws ephemeral secret with inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(region: "us-east-1", inline_policy:"policy")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method:"federation-token", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(5)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_POLICY)).to eq("policy")
    end
  end
  context "when creating aws ephemeral secret without method params" do
    it "all annotations are created" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method:"federation-token")
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(3)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_TTL)).to eq(1200)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_METHOD)).to eq("federation-token")
    end
  end
end
