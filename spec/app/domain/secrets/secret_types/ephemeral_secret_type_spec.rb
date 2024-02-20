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

describe "Ephemeral secret input validation" do
  let(:ephemeral_secret) do
    Secrets::SecretTypes::EphemeralSecretType.new
  end
  let(:ephemeral_params) do
    ActionController::Parameters.new(method: "federation-token",
                                     region: "us-east-1"
    )
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/ephemerals").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating ephemeral secret without ephemeral data" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral")
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with value" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", issuer: "issuer1", ttl: 120, type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral",  ephemeral: ephemeral, value: "secret")
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating ephemeral secret not under ephemeral branch" do
    before do
      StaticAccount.set_account("rspec")
      allow(Resource).to receive(:[]).with("rspec:policy:data/secrets").and_return("policy")
      $primary_schema = "public"
    end
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", issuer: "issuer1", ttl: 120, type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/secrets", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating ephemeral secret with no issuer" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", ttl: 120, type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with empty issuer" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", ttl: 120, issuer: "", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with issuer wrong type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", ttl: 120, issuer: 5, type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating ephemeral secret with no ttl" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with ttl wrong type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "aws", ttl: "", issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating ephemeral secret with no type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(ttl: 120, issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with empty type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "", ttl: 120, issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with type from wrong type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: 5, ttl: 120, issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating ephemeral secret with not supported type" do
    it "input validation fails" do
      ephemeral = ActionController::Parameters.new(type: "gcp", ttl: 120, issuer: "issuer1", type_params: ephemeral_params)
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
      expect { ephemeral_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterValueInvalid)
    end
  end
  context "when creating ephemeral secret" do
    let(:issuer_object) { 'issuer' }
    let(:issuer) do
      {
        id: "issuer2",
        max_ttl: 100
      }
    end
    context "with not existing issuer" do
      before do
        allow(Issuer).to receive(:where).with({:issuer_id=>"issuer2"}).and_return(issuer_object)
        allow(issuer_object).to receive(:first).and_return(nil)
        $primary_schema = "public"
      end
      it "input validation fails" do
        ephemeral = ActionController::Parameters.new(type: "aws", ttl: 120, issuer: "issuer2", type_params: ephemeral_params)
        params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
        expect { ephemeral_secret.input_validation(params)
        }.to raise_error(Exceptions::RecordNotFound)
      end
    end
    context "with existing issuer" do
      before do
        allow(Issuer).to receive(:where).with({:issuer_id=>"issuer2"}).and_return(issuer_object)
        allow(issuer_object).to receive(:first).and_return(issuer)
        $primary_schema = "public"
      end
      context "with wrong ttl" do
        it "input validation fails" do
          ephemeral = ActionController::Parameters.new(type: "aws", ttl: 120, issuer: "issuer2", type_params: ephemeral_params)
          params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
          expect { ephemeral_secret.input_validation(params)
          }.to raise_error(ApplicationController::BadRequestWithBody)
        end
      end
      context "aws ephemeral secret with no region" do
        it "input validation fails" do
          invalid_ephemeral_params = ActionController::Parameters.new(method: "federation-token")
          ephemeral = ActionController::Parameters.new(type: "aws", ttl: 20, issuer: "issuer2", type_params: invalid_ephemeral_params)
          params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
          expect { ephemeral_secret.input_validation(params)
          }.to raise_error(Errors::Conjur::ParameterMissing)
        end
      end
      context "aws ephemeral secret with all correct input" do
        it "input validation succeeds" do
          ephemeral = ActionController::Parameters.new(type: "aws", ttl: 20, issuer: "issuer2", type_params: ephemeral_params)
          params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", type: "ephemeral", ephemeral: ephemeral)
          expect { ephemeral_secret.input_validation(params)
          }.to_not raise_error
        end
      end
    end
  end
end
