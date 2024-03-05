require 'spec_helper'

describe "Dynamic secret input validation" do
  let(:dynamic_secret) do
    Secrets::SecretTypes::DynamicSecretType.new
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:policy:data/ephemerals").and_return("policy")
    $primary_schema = "public"
  end
  context "when creating dynamic secret with no name" do
    it "input validation fails" do
      params = ActionController::Parameters.new(branch: "data/ephemerals", issuer: "issuer1", ttl: 120,)
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating dynamic secret with value" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", issuer: "issuer1", ttl: 120, value: "secret")
      expect { dynamic_secret.input_validation(params)
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
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating dynamic secret with no issuer" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120)
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating dynamic secret with empty issuer" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "")
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with issuer wrong type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: 5)
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterTypeInvalid)
    end
  end
  context "when creating ephemeral secret with no ttl" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", issuer: "issuer1")
      expect { dynamic_secret.input_validation(params)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when creating ephemeral secret with ttl wrong type" do
    it "input validation fails" do
      params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: "", issuer: "issuer1")
      expect { dynamic_secret.input_validation(params)
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
        params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer2")
        expect { dynamic_secret.input_validation(params)
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
          params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 120, issuer: "issuer2")
          expect { dynamic_secret.input_validation(params)
          }.to raise_error(ApplicationController::BadRequestWithBody)
        end
      end
      context "aws ephemeral secret with all correct input" do
        it "input validation succeeds" do
          params = ActionController::Parameters.new(name: "secret1", branch: "data/ephemerals", ttl: 20, issuer: "issuer2")
          expect { dynamic_secret.input_validation(params)
          }.to_not raise_error
        end
      end
    end
  end
end