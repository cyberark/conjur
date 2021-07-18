# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Constraints::NonPermittedConstraint) do
  let(:non_permitted_constraint) { ["iat", "nbf", "exp", "iss"] }
  let(:raised_error) { ::Errors::Authentication::Constraints::NonPermittedRestrictionGiven }

  subject(:constraint) do
    Authentication::Constraints::NonPermittedConstraint.new(non_permitted: non_permitted_constraint)
  end

  context "when validating empty array" do
    subject do
      constraint.validate(resource_restrictions: [])
    end

    it "not raises an error" do
      expect { subject }.to_not raise_error
    end
  end

  context "when validating one allowed restriction" do
    subject do
      constraint.validate(resource_restrictions: ["ref"])
    end

    it "not raises an error" do
      expect { subject }.to_not raise_error
    end
  end

  context "when validating two allowed restriction" do
    subject do
      constraint.validate(resource_restrictions: ["ref", "sub"])
    end

    it "not raises an error" do
      expect { subject }.to_not raise_error
    end
  end

  context "when validating one non permitted restriction" do
    subject do
      constraint.validate(resource_restrictions: ["exp"])
    end

    it "raises an error" do
      expect { subject }.to raise_error(raised_error)
    end
  end

  context "when validating two non permitted restrictions" do
    subject do
      constraint.validate(resource_restrictions: ["exp", "iat"])
    end

    it "raises an error" do
      expect { subject }.to raise_error(raised_error)
    end
  end

  context "when validating one non permitted and one permitted restriction" do
    subject do
      constraint.validate(resource_restrictions: ["exp", "ref"])
    end

    it "raises an error" do
      expect { subject }.to raise_error(raised_error)
    end
  end

  context "when validating one permitted and one non permitted restriction" do
    subject do
      constraint.validate(resource_restrictions: ["ref", "nbf"])
    end

    it "raises an error" do
      expect { subject }.to raise_error(raised_error)
    end
  end
end
