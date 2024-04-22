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

  context "when creating dynamic secret with value" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", issuer: "issuer1", ttl: 120, value: "secret")
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when creating dynamic secret not under dynamic branch" do
    before do
      StaticAccount.set_account("rspec")
      allow(Resource).to receive(:[]).with("rspec:policy:data/secrets").and_return("policy")
      $primary_schema = "public"
    end
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/secrets", type: "dynamic", issuer: "issuer1", ttl: 120)
      expect { dynamic_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end

  context "when creating dynamic secret" do
    let(:issuer_object) { 'issuer' }
    let(:issuer) do
      {
        id: "issuer2",
        max_ttl: 1400,
        issuer_type: "aws",
      }
    end
    context "with not existing issuer" do
      before do
        allow(Issuer).to receive(:where).with({:issuer_id=>"issuer2"}).and_return(issuer_object)
        allow(issuer_object).to receive(:first).and_return(nil)
        $primary_schema = "public"
      end
      it "input validation fails" do
        params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 1200, issuer: "issuer2")
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
          params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 2200, issuer: "issuer2")
          expect { dynamic_secret.create_input_validation(params)
          }.to raise_error(ApplicationController::UnprocessableEntity)
        end
      end
      context "when validating create request" do
        let(:params) do
          ActionController::Parameters.new(branch: "data/dynamic", name: "secret1", issuer: "issuer2", ttl: 920, method: "federation-token")
        end

        it "correct validators are being called for each field" do
          expect(dynamic_secret).to receive(:validate_field_required).with(:issuer,{type: String,value: "issuer2"})

          expect(dynamic_secret).to receive(:validate_field_type).with(:issuer,{type: String,value: "issuer2"})
          expect(dynamic_secret).to receive(:validate_field_type).with(:ttl,{type: Numeric,value: 920})

          expect(dynamic_secret).to receive(:validate_id).with(:issuer,{type: String,value: "issuer2"})

          dynamic_secret.send(:dynamic_input_validation, params)
        end
      end
      context "aws dynamic secret with all correct input" do
        it "input validation succeeds" do
          params = ActionController::Parameters.new(name: "secret1", branch: "data/dynamic", ttl: 920, issuer: "issuer2", method: "assume-role")
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
      it "failed on finding secret type" do
        allow(secret).to receive(:annotations).and_return([])
        expect { federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        }.to raise_error(ApplicationController::BadRequestWithBody)
      end
    end
    context "and with only method annotation" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token')])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"federation-token\",\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "and custom annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token'), Annotation.new(name: 'description', value: 'desc'), Annotation.new(name: 'annotation_to_delete', value: 'delete')])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"annotation_to_delete\",\"value\":\"delete\"}],\"permissions\":[]}")
      end
    end
    context "required fields and custom annotations" do
      it "dynamic required fields return as defined with custom annotations" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token'), Annotation.new(name: 'description', value: 'desc'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120')])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[]}")
      end
    end
    context "part method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token'), Annotation.new(name: 'dynamic/region', value: 'us-east-1'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120')])
        json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"method_params\":{\"region\":\"us-east-1\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "all method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token'), Annotation.new(name: 'dynamic/region', value: 'us-east-1'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120'), Annotation.new(name: 'dynamic/inline-policy', value: 'policy')])
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
      it "failed on finding secret type" do
        allow(secret).to receive(:annotations).and_return([])
        expect { assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        }.to raise_error(ApplicationController::BadRequestWithBody)
      end
    end
    context "and without only method annotation" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'assume-role')])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "and custom annotations" do
      it "dynamic required fields return empty" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'assume-role'), Annotation.new(name: 'description', value: 'desc'), Annotation.new(name: 'annotation_to_delete', value: 'delete')])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"\",\"ttl\":\"\",\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"\"},\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"},{\"name\":\"annotation_to_delete\",\"value\":\"delete\"}],\"permissions\":[]}")
      end
    end
    context "required fields and custom annotations" do
      it "dynamic required fields return as defined with custom annotations" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'assume-role'), Annotation.new(name: 'description', value: 'desc'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120'),  Annotation.new(name: 'dynamic/role-arn', value: 'role')])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\"},\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[]}")
      end
    end
    context "part method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'assume-role'), Annotation.new(name: 'dynamic/region', value: 'us-east-1'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120'), Annotation.new(name: 'dynamic/role-arn', value: 'role')])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\",\"region\":\"us-east-1\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
    context "all method params" do
      it "all fields returned as expected" do
        allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'assume-role'), Annotation.new(name: 'dynamic/region', value: 'us-east-1'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120'), Annotation.new(name: 'dynamic/inline-policy', value: 'policy'), Annotation.new(name: 'dynamic/role-arn', value: 'role')])
        json_result = assume_role_dynamic_secret.as_json(branch, secret_name, secret)
        expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"assume-role\",\"method_params\":{\"role_arn\":\"role\",\"region\":\"us-east-1\",\"inline_policy\":\"policy\"},\"annotations\":[],\"permissions\":[]}")
      end
    end
  end
  context "dynamic secret with permissions and annotations" do
    it "all fields are returned with annotations and permissions" do
      allow(Permission).to receive(:select).and_return([{:role_id=>"conjur:user:alice", :privileges=>["update", "read"]}]) # Return empty array
      allow(secret).to receive(:annotations).and_return([Annotation.new(name: 'dynamic/method', value: 'federation-token'), Annotation.new(name: 'description', value: 'desc'), Annotation.new(name: 'dynamic/issuer', value: 'issuer1'), Annotation.new(name: 'dynamic/ttl', value: '120')])
      json_result = federation_token_dynamic_secret.as_json(branch, secret_name, secret)
      expect(json_result).to eq("{\"branch\":\"/data/dynamic/secrets\",\"name\":\"dynamic_secret\",\"issuer\":\"issuer1\",\"ttl\":120,\"method\":\"federation-token\",\"annotations\":[{\"name\":\"description\",\"value\":\"desc\"}],\"permissions\":[{\"subject\":{\"id\":\"alice\",\"kind\":\"user\"},\"privileges\":[\"update\",\"read\"]}]}")
    end
  end
end
