# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Constraints::AnyConstraint do
  context "Given AnyConstraint initialized with 1 restriction" do
    let(:any_one_restriction) { ["required"] }
    let(:not_required_restriction) { "not-required" }
    let(:raised_error) { ::Errors::Authentication::Constraints::RoleMissingRequiredConstraints }
    let(:expected_error_message) { /#{Regexp.escape(any_one_restriction.to_s)}/ }

    subject(:constraint) do
      Authentication::Constraints::AnyConstraint.new(any: any_one_restriction)
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
        constraint.validate(resource_restrictions: [not_required_restriction])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with only the required restriction" do
      subject do
        constraint.validate(resource_restrictions: any_one_restriction)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with the required restriction and more" do
      subject do
        constraint.validate(resource_restrictions: any_one_restriction + [not_required_restriction])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "Given AnyConstraint initialized with 2 restrictions" do
    let(:any_two_restrictions) { %w[required_first required_second] }
    let(:not_required_restriction) { "not-required" }
    let(:raised_error) { ::Errors::Authentication::Constraints::RoleMissingRequiredConstraints }
    let(:expected_error_message) { /#{Regexp.escape(any_two_restrictions.to_s)}/ }

    subject(:constraint) do
      Authentication::Constraints::AnyConstraint.new(any: any_two_restrictions)
    end

    context "when validating empty array" do
      subject do
        constraint.validate(resource_restrictions: [])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating without any of the required restrictions" do
      subject do
        constraint.validate(resource_restrictions: [not_required_restriction])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with the first required restriction" do
      subject do
        constraint.validate(resource_restrictions: [any_two_restrictions.first])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with the second required restriction" do
      subject do
        constraint.validate(resource_restrictions: [any_two_restrictions.second])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with both of the required restrictions" do
      subject do
        constraint.validate(resource_restrictions: any_two_restrictions)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with both of the required restrictions and more" do
      subject do
        constraint.validate(resource_restrictions: any_two_restrictions + [not_required_restriction])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
