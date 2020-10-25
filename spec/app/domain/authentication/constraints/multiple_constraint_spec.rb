# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Constraints::MultipleConstraint do
  context "Given MultipleConstraint initialized with 1 constraint" do
    let(:inner_constraint) { double("InnerConstraint") }
    let(:resource_restrictions) { %w(restriction_first restriction_second) }

    subject(:constraint) do
      Authentication::Constraints::MultipleConstraint.new(inner_constraint)
    end

    context "when validating an array" do
      it "calls validate on inner constraint" do
        expect(inner_constraint).to receive(:validate).with(resource_restrictions: resource_restrictions)
        constraint.validate(resource_restrictions: resource_restrictions)
      end
    end
  end

  context "Given MultipleConstraint initialized with 2 constraints" do
    let(:inner_constraint_first) { double("InnerConstraint") }
    let(:inner_constraint_second) { double("InnerConstraint") }
    let(:resource_restrictions) { %w(restriction_first restriction_second) }

    subject(:constraint) do
      Authentication::Constraints::MultipleConstraint.new(inner_constraint_first, inner_constraint_second)
    end

    context "when validating an array" do
      it "calls validate on both inner constraints by their order" do
        expect(inner_constraint_first).to receive(:validate).with(resource_restrictions: resource_restrictions).ordered
        expect(inner_constraint_second).to receive(:validate).with(resource_restrictions: resource_restrictions).ordered
        constraint.validate(resource_restrictions: resource_restrictions)
      end
    end
  end
end
