require 'spec_helper'

describe "Secret type creation" do
  let(:secret_type_factory) do
    SecretTypeFactory.new
  end
  context "when creating secret without type" do
    it "creation fails" do
      expect { secret_type_factory.create_secret_type(nil)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating secret with empty type" do
    it "creation fails" do
      expect { secret_type_factory.create_secret_type("")
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating secret with not existent type" do
    it "creation fails" do
      expect { secret_type_factory.create_secret_type("simple")
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating secret with numeric type" do
    it "creation fails" do
      expect { secret_type_factory.create_secret_type(5)
      }.to raise_error(ApplicationController::BadRequestWithBody)
    end
  end
  context "when creating static secret" do
    it "creation succeeds" do
      expect(secret_type_factory.create_secret_type("static").is_a?(Secrets::SecretTypes::StaticSecretType)).to eq(true)
    end
  end
  context "when creating ephemeral secret" do
    it "creation succeeds" do
      expect(secret_type_factory.create_secret_type("ephemeral").is_a?(Secrets::SecretTypes::EphemeralSecretType)).to eq(true)
    end
  end
end
