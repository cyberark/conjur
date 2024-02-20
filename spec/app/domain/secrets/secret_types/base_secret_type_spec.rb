require 'spec_helper'

describe "Base secret input validation" do
  let(:secret) do
    Secrets::SecretTypes::SecretBaseType.new
  end
  context "when creating secret with empty branch" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "")
      expect { secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
end
