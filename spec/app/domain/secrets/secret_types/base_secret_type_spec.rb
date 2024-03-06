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
  context "when creating secret with empty name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "", branch: "data")
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with no name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data")
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with name not string" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data", name: 5)
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating secret with unsupported symbols in its name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "se#cret/not_valid", branch: "data")
      expect { secret.create_input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating secret with too long name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secretstoolongggggggggggggggggggggggggggggggggggggggggggggggg", branch: "data")
      expect { secret.create_input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating secret with all supported symbols in its name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "seCret0_5Name", branch: "data")
      expect { secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
  context "when creating secret with only numbers in its name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "12345", branch: "data")
      expect { secret.create_input_validation(params)
      }.to_not raise_error
    end
  end
  context "when creating secret with empty branch" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "")
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with no branch" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1")
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating secret with branch not string" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: 5)
      expect { secret.create_input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
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
