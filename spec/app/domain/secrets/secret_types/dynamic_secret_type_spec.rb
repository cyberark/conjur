require 'spec_helper'

describe "Dynamic secret create input validation" do
  let(:dynamic_secret) do
    Secrets::SecretTypes::DynamicSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/dynamic").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating dynamic secret with no name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/dynamic", issuer: "issuer1", ttl: 120,)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating dynamic secret with value" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", issuer: "issuer1", ttl: 120, value: "secret")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating dynamic secret not under ephemeral branch" do
    before do
      StaticAccount.set_account("rspec")
      allow(Resource).to receive(:[]).with("rspec:policy:data/secrets").and_return("policy")
      $primary_schema = "public"
    end
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/secrets", type: "ephemeral", issuer: "issuer1", ttl: 120)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating dynamic secret with no issuer" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating dynamic secret with empty issuer" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with issuer wrong type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: 5)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating ephemeral secret with no ttl" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", issuer: "issuer1")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with ttl wrong type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: "", issuer: "issuer1")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
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
        params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer2")
        expect { dynamic_secret.create_input_validation(params)
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
          params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 120, issuer: "issuer2")
          expect { dynamic_secret.create_input_validation(params)
          }.to raise_error(ApplicationController::BadRequestWithBody)
        end
      end
      context "aws ephemeral secret with all correct input" do
        it "input validation succeeds" do
          params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 20, issuer: "issuer2")
          expect { dynamic_secret.create_input_validation(params)
          }.to_not raise_error
        end
      end
    end
  end
end

describe "Dynamic secret as json" do
  let(:assume_role_dynamic_secret) do
    Secrets::SecretTypes::AWSAssumeRoleDynamicSecretType.new
  end
  let(:federation_token_dynamic_secret) do
    Secrets::SecretTypes::AWSFederationTokenDynamicSecretType.new
  end
  let(:branch) do
    "data/dynamic/secrets"
  end
  let(:secret_name) do
    "dynamic_secret"
  end
  let(:secret) do
    double("Resource")
  end

  before do
    StaticAccount.set_account("rspec")
    $primary_schema = "public"
    # Stubbing the Permission model
    allow(secret).to receive(:id).and_return("id")
    allow(Permission).to receive(:where).and_return(Permission)
    allow(Permission).to receive(:group).and_return(Permission)
  end

  context "federation token secret without permissions" do
    before do
      allow(Permission).to receive(:select).and_return([]) # Return empty array
    end
    context "and without any annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"federation-token\",\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "and custom annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([{:name=>"description", :value=>"desc"}, {:name=>"annotation_to_delete", :value=>"delete"}])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"annotation_to_delete\",\"value\":\"delete\"}],\"permissions\":[]}")
      end
    end
    context "required fields and custom annotations" do
      it "dynamic required fields return as defined with custom annotations" do
        allow(secret).to receive(:annotations).and_return([{:name=>"description", :value=>"desc"}, {:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[]}")
      end
    end
    context "part method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([{:name=>"dynamic/region", :value=>"us-east-1"}, {:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"method_params\":{\"region\":\"us-east-1\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "all method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([{:name=>"dynamic/region", :value=>"us-east-1"},{:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}, {:name=>"dynamic/inline-policy", :value=>"policy"}])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"method_params\":{\"region\":\"us-east-1\",\"inline_policy\":\"policy\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
  end
  context "assume role secret without permissions" do
    before do
      allow(Permission).to receive(:select).and_return([]) # Return empty array
    end
    context "and without any annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "and custom annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([{:name=>"description", :value=>"desc"}, {:name=>"annotation_to_delete", :value=>"delete"}])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"\"},\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"annotation_to_delete\",\"value\":\"delete\"}],\"permissions\":[]}")
      end
    end
    context "required fields and custom annotations" do
      it "dynamic required fields return as defined with custom annotations" do
        allow(secret).to receive(:annotations).and_return([{:name=>"description", :value=>"desc"}, {:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}, {:name=>"dynamic/role-arn", :value=>"role"}])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\"},\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[]}")
      end
    end
    context "part method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([{:name=>"dynamic/region", :value=>"us-east-1"}, {:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}, {:name=>"dynamic/role-arn", :value=>"role"}])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\",\"region\":\"us-east-1\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "all method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([{:name=>"dynamic/region", :value=>"us-east-1"},{:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}, {:name=>"dynamic/inline-policy", :value=>"policy"}, {:name=>"dynamic/role-arn", :value=>"role"}])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\",\"region\":\"us-east-1\",\"inline_policy\":\"policy\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
  end
  context "dynamic secret with permissions and annotations" do
    it "all fields are returned with annotations and permissions" do
      allow(Permission).to receive(:select).and_return([{:role_id=>"conjur:user:alice", :privileges=>["update", "read"]}]) # Return empty array
      allow(secret).to receive(:annotations).and_return([{:name=>"description", :value=>"desc"}, {:name=>"dynamic/issuer", :value=>"issuer1"}, {:name=>"dynamic/ttl", :value=>120}])
      json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
      expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[{\"subject\":{\"id\":\"alice\",\"kind\":\"user\"},\"privileges\":[\"update\",\"read\"]}]}")
    end
  end
end
