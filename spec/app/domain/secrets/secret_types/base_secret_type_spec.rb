require 'spec_helper'

describe "Base secret create input validation" do
  let(:secret) do
    Secrets::SecretTypes::SecretBaseType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data").and_return("data")
    $primary_schema = "public"
  end
  context "when validating create request" do
    let(:params) do
      ActionController::Parameters.new(name: "secret1", branch: "data")
    end

    it "correct validators are being called for each field" do
      expect(secret).to receive(:validate_field_required).with(:name,{type: String,value: "secret1"})
      expect(secret).to receive(:validate_field_required).with(:branch,{type: String,value: "data"})

      expect(secret).to receive(:validate_field_type).with(:name,{type: String,value: "secret1"})
      expect(secret).to receive(:validate_field_type).with(:branch,{type: String,value: "data"})

      expect(secret).to receive(:validate_id).with(:name,{type: String,value: "secret1"})
      expect(secret).to receive(:validate_path).with(:branch,{type: String,value: "data"})

      secret.create_input_validation(params)
    end
  end

  context "when creating secret with only numbers in its name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "12345", branch: "data")
      expect { secret.create_input_validation(params)
      }.to_not raise_error
    end
  end

  context "when creating secret with not existent branch" do
    before do
      allow(Resource).to receive(:[]).with("rspec:policy:luba").and_return(nil)
      $primary_schema = "public"
    end
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "luba")
      expect { secret.create_input_validation(params)
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end
end

describe "Base secret update input validation" do
  let(:static_secret) do
    Secrets::SecretTypes::StaticSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/secrets").and_return("policy")
    allow(Resource).to receive(:[]).with("rspec:variable:data/secrets/secret1").and_return("secret")
    allow(Resource).to receive(:[]).with("rspec:variable:data/secrets/secret2").and_return(nil)
    $primary_schema = "public"
  end
  context "when update secret with branch in body" do
    it "input validation fails" do
      body_params = ActionController::Parameters.new(mime_type:"text", branch: "data/secrets")
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1")
      expect { static_secret.update_input_validation(params, body_params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when update secret with name in body" do
    it "input validation fails" do
      body_params = ActionController::Parameters.new(mime_type:"text", name:"secret1")
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1")
      expect { static_secret.update_input_validation(params, body_params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when update not existent secret" do
    it "input validation fails" do
      body_params = ActionController::Parameters.new(mime_type:"text")
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret2")
      expect { static_secret.update_input_validation(params, body_params)
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end
end
