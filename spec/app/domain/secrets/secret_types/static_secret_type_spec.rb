require 'spec_helper'

describe "Static secret create input validation" do
  let(:static_secret) do
    Secrets::SecretTypes::StaticSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/dynamic").and_return("policy")
    allow(Resource).to receive(:[]).with("rspec:policy:data/secrets").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating secret with empty mime_type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1", mime_type: "")
      expect { static_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when creating secret with invalid mime_type type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1", mime_type: 5)
      expect { static_secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating secret under dynamic branch" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      expect { static_secret.create_input_validation(params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
end

describe "Static secret update input validation" do
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
  context "when update secret with empty mime_type" do
    it "input validation fails" do
      body_params = ActionController::Parameters.new(mime_type:"")
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1")
      expect { static_secret.update_input_validation(params, body_params)
      }.to raise_error(ApplicationController::UnprocessableEntity)
    end
  end
  context "when update secret with invalid mime_type type" do
    it "input validation fails" do
      body_params = ActionController::Parameters.new(mime_type:5)
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1")
      expect { static_secret.update_input_validation(params, body_params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
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

describe "Static secret get input validation" do
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
  context "when get not existent secret" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret2")
      expect { static_secret.get_input_validation(params)
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end
end

describe "Annotations conversion" do
  let(:static_secret) do
    Secrets::SecretTypes::StaticSecretType.new
  end
  context "when creating secret with mime_type and no annotations" do
    it "mime type annotation is added" do
      params = ActionController::Parameters.new(branch: "data/dynamic", mime_type: "text/plain")
      annotations =  static_secret.send(:merge_annotations, params)
      expect(annotations.length).to eq(1)
      expect(get_field_value(annotations, "value", "name", 'conjur/mime_type')).to eq("text/plain")
    end
  end
  context "when creating secret with no mime_type and no annotations" do
    it "mime type annotation is not added" do
      params = ActionController::Parameters.new(branch: "data/dynamic")
      annotations =  static_secret.send(:merge_annotations, params)
      expect(annotations.length).to eq(0)
    end
  end
  context "when creating secret with mime_type and annotations" do
    it "All annotations are added" do
      description_param = ActionController::Parameters.new(name:"description", value:"desc")
      kind_param = ActionController::Parameters.new(name:"kind", value:"ephemeral")
      annotations_params = [description_param, kind_param]

      params = ActionController::Parameters.new(branch: "data/ephemerals", mime_type: "text/plain", annotations: annotations_params)
      annotations =  static_secret.send(:merge_annotations, params)
      expect(annotations.length).to eq(3)
      expect(get_field_value(annotations, "value", "name", 'conjur/mime_type')).to eq("text/plain")
      expect(get_field_value(annotations, "value", "name", 'description')).to eq("desc")
      expect(get_field_value(annotations, "value", "name", 'kind')).to eq("ephemeral")
    end
  end
end
