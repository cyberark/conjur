# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Constraints::RequiredConstraint do
  context "Given RequiredConstraint initialized with 1 restriction" do
    let(:required_restriction) { ["required"] }
    let(:not_required_restrictions) { %w[not_required_first not_required_second] }
    let(:raised_error) { ::Errors::Authentication::Constraints::RoleMissingConstraints }
    let(:expected_error_message) { /#{Regexp.escape(required_restriction.to_s)}/ }

    subject(:constraint) do
      Authentication::Constraints::RequiredConstraint.new(required: required_restriction)
    end

    context "when validating empty array" do
      subject do
        constraint.validate(resource_restrictions: [])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating without the required restriction" do
      subject do
        constraint.validate(resource_restrictions: not_required_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with only the required restriction" do
      subject do
        constraint.validate(resource_restrictions: required_restriction)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with the required restriction and more" do
      subject do
        constraint.validate(resource_restrictions: required_restriction + not_required_restrictions)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "Given RequiredConstraint initialized with 2 restrictions" do
    let(:required_two_restrictions) { %w[required_first required_second] }
    let(:not_required_restrictions) { %w[not_required_first not_required_second] }
    let(:raised_error) { ::Errors::Authentication::Constraints::RoleMissingConstraints }

    subject(:constraint) do
      Authentication::Constraints::RequiredConstraint.new(required: required_two_restrictions)
    end

    context "when validating empty array" do
      let(:expected_error_message) { /#{Regexp.escape(required_two_restrictions.to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: [])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating without any of the required restrictions" do
      let(:expected_error_message) { /#{Regexp.escape(required_two_restrictions.to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: not_required_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with the first required restriction" do
      let(:resource_restrictions) { [required_two_restrictions.first] }
      let(:expected_error_message) { /#{Regexp.escape((required_two_restrictions - resource_restrictions).to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: resource_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with the second required restriction" do
      let(:resource_restrictions) { [required_two_restrictions.second] }
      let(:expected_error_message) { /#{Regexp.escape((required_two_restrictions - resource_restrictions).to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: resource_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with both of the required restrictions" do
      subject do
        constraint.validate(resource_restrictions: required_two_restrictions)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with both of the required restrictions and more" do
      subject do
        constraint.validate(resource_restrictions: required_two_restrictions + not_required_restrictions)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
