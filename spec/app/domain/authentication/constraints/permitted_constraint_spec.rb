# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Constraints::PermittedConstraint do
  context "Given PermittedConstraint initialized with 1 restriction" do
    let(:permitted_restriction) { ["permitted"] }
    let(:not_permitted_restrictions) { %w(not_permitted_first not_permitted_second) }
    let(:raised_error) { ::Errors::Authentication::Constraints::ConstraintNotSupported }
    let(:expected_error_message) { /'#{Regexp.escape(not_permitted_restrictions.to_s)}'.*#{permitted_restriction}/ }

    subject(:constraint) do
      Authentication::Constraints::PermittedConstraint.new(permitted: permitted_restriction)
    end

    context "when validating empty array" do
      subject do
        constraint.validate(resource_restrictions: [])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating without the permitted restriction" do
      subject do
        constraint.validate(resource_restrictions: not_permitted_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with only the permitted restriction" do
      subject do
        constraint.validate(resource_restrictions: permitted_restriction)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with the permitted restriction and more" do
      subject do
        constraint.validate(resource_restrictions: permitted_restriction + not_permitted_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end
  end

  context "Given PermittedConstraint initialized with 2 restrictions" do
    let(:permitted_two_restrictions) { %w(permitted_first permitted_second) }
    let(:not_permitted_restrictions) { %w(not_permitted_first not_permitted_second) }
    let(:raised_error) { ::Errors::Authentication::Constraints::ConstraintNotSupported }
    let(:expected_error_message) { /'#{Regexp.escape(not_permitted_restrictions.to_s)}'.*#{permitted_two_restrictions.to_s}/ }

    subject(:constraint) do
      Authentication::Constraints::PermittedConstraint.new(permitted: permitted_two_restrictions)
    end

    context "when validating empty array" do
      subject do
        constraint.validate(resource_restrictions: [])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating without any of the permitted restrictions" do
      subject do
        constraint.validate(resource_restrictions: not_permitted_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with the first permitted restriction" do
      subject do
        constraint.validate(resource_restrictions: [permitted_two_restrictions.first])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with the second permitted restriction" do
      subject do
        constraint.validate(resource_restrictions: [permitted_two_restrictions.second])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with both of the permitted restrictions" do
      subject do
        constraint.validate(resource_restrictions: permitted_two_restrictions)
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with both of the permitted restrictions and more" do
      subject do
        constraint.validate(resource_restrictions: permitted_two_restrictions + not_permitted_restrictions)
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end
  end
end
