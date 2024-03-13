require 'spec_helper'

describe "Static secret input validation" do
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
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with invalid mime_type type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/secrets", name:"secret1", mime_type: 5)
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating secret under dynamic branch" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/dynamic", name:"secret1")
      expect { static_secret.input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
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

      params = ActionController::Parameters.new(branch: "data/dynamic", mime_type: "text/plain", annotations: annotations_params)
      annotations =  static_secret.send(:merge_annotations, params)
      expect(annotations.length).to eq(3)
      expect(get_field_value(annotations, "value", "name", 'conjur/mime_type')).to eq("text/plain")
      expect(get_field_value(annotations, "value", "name", 'description')).to eq("desc")
      expect(get_field_value(annotations, "value", "name", 'kind')).to eq("ephemeral")
    end
  end
end
