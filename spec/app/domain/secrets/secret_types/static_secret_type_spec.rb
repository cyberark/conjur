require 'spec_helper'

describe "Static secret input validation" do
  let(:static_secret) do
    SecretTypeFactory.new.create_secret_type("static")
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/ephemerals").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating secret with empty mime_type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/ephemerals", name:"secret1", type: "static", mime_type: "")
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with invalid mime_type type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/ephemerals", name:"secret1", type: "static", mime_type: 5)
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
end

describe "Static secret annotations conversion" do
  let(:static_secret) do
    SecretTypeFactory.new.create_secret_type("static")
  end
  context "when creating secret with mime_type" do
    it "mime type annotation is added" do
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "static", mime_type: "text/plain")
      annotations = static_secret.convert_fields_to_annotations(params)
      expect(annotations.length).to eq(2)
      expect(annotations['conjur/kind']).to eq("static")
      expect(annotations['conjur/mime_type']).to eq("text/plain")
    end
  end
  context "when creating secret with no mime_type" do
    it "mime type annotation is not added" do
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "static")
      annotations = static_secret.convert_fields_to_annotations(params)
      expect(annotations.length).to eq(1)
      expect(annotations['conjur/kind']).to eq("static")
      expect(annotations.key?('conjur/mime_type')).to eq(false)
    end
  end
end
