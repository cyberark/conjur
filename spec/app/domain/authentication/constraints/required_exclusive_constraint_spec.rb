# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Constraints::RequiredExclusiveConstraint) do
  context "Given RequiredExclusiveConstraint initialized with 3 restrictions" do
    let(:reqx_restrictions) { %w[reqx_one reqx_two reqx_three] }
    let(:additional_restriction) { "additional" }
    let(:raised_error) { ::Errors::Authentication::Constraints::IllegalRequiredExclusiveCombination }

    subject(:constraint) do
      Authentication::Constraints::RequiredExclusiveConstraint.new(required_exclusive: reqx_restrictions)
    end

    context "when validating with no ReqX restrictions" do
      let(:expected_error_message) { /#{Regexp.escape(reqx_restrictions.to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: [additional_restriction])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with one ReqX restriction" do
      subject do
        constraint.validate(resource_restrictions: [reqx_restrictions.first, additional_restriction])
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "when validating with many ReqX restrictions" do
      let(:resource_restrictions) { reqx_restrictions[1, 2] }
      let(:expected_error_message) { /#{Regexp.escape(resource_restrictions.to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: resource_restrictions + [additional_restriction])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

    context "when validating with all ReqX restrictions" do
      let(:expected_error_message) { /#{Regexp.escape(reqx_restrictions.to_s)}/ }

      subject do
        constraint.validate(resource_restrictions: reqx_restrictions + [additional_restriction])
      end

      it "raises an error" do
        expect { subject }.to raise_error(raised_error, expected_error_message)
      end
    end

  end
end
