# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Constraints::NotEmptyConstraint) do
  let(:right_email) { "admin@example.com" }
  let(:username) { "admin" }

  let(:no_restrictinos){ [] }

  let(:one_restriction) {
    [
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_email", value: right_email)
    ]
  }

  let(:two_restrictions) {
    [
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_email", value: right_email),
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "username", value: username)
    ]
  }

  context "NotEmptyConstraint" do
    subject do
      ::Authentication::Constraints::NotEmptyConstraint.new
    end

    it "validate runs successfully for one restriction" do
      expect { subject.validate(resource_restrictions: one_restriction) }.to_not raise_error
    end

    it "validate runs successfully for two restrictions" do
      expect { subject.validate(resource_restrictions: two_restrictions) }.to_not raise_error
    end

    it "validate raises EmptyAnnotationsListConfigured when there are not annotations" do
      expect { subject.validate(resource_restrictions: no_restrictinos) }.to raise_error(Errors::Authentication::Constraints::RoleMissingAnyRestrictions)
    end
  end
end
