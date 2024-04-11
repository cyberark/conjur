require 'spec_helper'

describe "AWS Assume Role Dynamic secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 2000,
      issuer_type: "aws"
    }
  end
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
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
      ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params)
    end

    it "correct validators are being called for each field" do
      expect(dynamic_secret).to receive(:validate_field_required).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})
      expect(dynamic_secret).to receive(:validate_field_type).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})
      expect(dynamic_secret).to receive(:validate_role_arn).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})


      expect(dynamic_secret).to receive(:validate_field_type).with(:region,{type: String,value: "us-east-1"})
      expect(dynamic_secret).to receive(:validate_region).with(:region,{type: String,value: "us-east-1"})

      expect(dynamic_secret).to receive(:validate_field_type).with(:inline_policy,{type: String,value: "policy"})

      dynamic_secret.send(:input_validation, params)
    end
  end

  context "when creating aws assume role dynamic secret with no method params" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end

  context "when creating aws assume role dynamic secret with ttl bigger then issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 2200, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end

  context "when creating aws assume role dynamic secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
end

describe "AWS Assume Role Dynamic update secret input validation" do
  let(:issuer_object) { 'issuer' }
  let(:issuer) do
    {
      id: "issuer1",
      max_ttl: 2000,
      issuer_type: "aws"
    }
  end
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
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
      ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method_params: method_params)
    end

    it "correct validators are being called for each field" do
      expect(dynamic_secret).to receive(:validate_field_required).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})
      expect(dynamic_secret).to receive(:validate_field_type).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})
      expect(dynamic_secret).to receive(:validate_role_arn).with(:role_arn,{type: String,value: "arn:aws:iam::123456789012:role/my-role-name"})


      expect(dynamic_secret).to receive(:validate_field_type).with(:region,{type: String,value: "us-east-1"})
      expect(dynamic_secret).to receive(:validate_region).with(:region,{type: String,value: "us-east-1"})

      expect(dynamic_secret).to receive(:validate_field_type).with(:inline_policy,{type: String,value: "policy"})

      dynamic_secret.send(:input_validation, params)
    end
  end
  context "when updating aws assume role dynamic secret with no method params" do
    it "then the input validation fails" do
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 1200, issuer: "issuer1")
      expect { dynamic_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when updating aws assume role dynamic secret with ttl bigger then issuer" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 2200, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params) }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when updating aws assume role dynamic secret with correct input" do
    it "then the input validation passes" do
      method_params = ActionController::Parameters.new(role_arn: "arn:aws:iam::123456789012:role/my-role-name")
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      body_params = ActionController::Parameters.new(ttl: 1200, issuer: "issuer1", method_params: method_params)
      expect { dynamic_secret.update_input_validation(params, body_params) }.to_not raise_error
    end
  end
end

describe "AWS dynamic secret annotations creation" do
  let(:dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
  end
  context "when creating aws dynamic secret without inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(role_arn: "role", region: "us-east-1")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method:"assume-role", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(5)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_ISSUER)).to eq("issuer1")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_TTL)).to eq(1200)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::DynamicSecretType::DYNAMIC_METHOD)).to eq("assume-role")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_ROLE_ARN)).to eq("role")
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_REGION)).to eq("us-east-1")
    end
  end
  context "when creating aws dynamic secret with inline policy" do
    it "all annotations are created" do
      method_params = ActionController::Parameters.new(role_arn: "role", region: "us-east-1", inline_policy:"policy")
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer1", method:"assume-role", method_params: method_params)
      annotations = dynamic_secret.send(:convert_fields_to_annotations, params)

      expect(annotations.length).to eq(6)
      expect(get_field_value(annotations, "value", "name", Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType::DYNAMIC_POLICY)).to eq("policy")
    end
  end
end
