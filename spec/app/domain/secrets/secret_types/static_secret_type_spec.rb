require 'spec_helper'

describe "Static secret input validation" do
  let(:static_secret) do
    SecretTypeFactory.new.create_secret_type("static")
  end
  context "when creating secret with empty mime_type" do
    it "input validation fails" do
      #static_secret = SecretTypeFactory.new.create_secret_type("static")
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "static", mime_type: "")
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with invalid mime_type type" do
    it "input validation fails" do
      #static_secret = SecretTypeFactory.new.create_secret_type("static")
      params = ActionController::Parameters.new(branch: "data/ephemerals", type: "static", mime_type: 5)
      expect { static_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
end
