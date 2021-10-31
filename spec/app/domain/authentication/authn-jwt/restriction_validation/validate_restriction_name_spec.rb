# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionName') do

  let(:restriction_name_validator) {
    ::Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionName.new
  }

  valid_cases = {
    "Non nested annotation":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a", value: "val"),
    "2 levels nested annotation":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a/b", value: "val"),
    "3 levels nested annotation":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a/b/c", value: "val"),
    "annotation with dot in the name":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "x.k8s", value: "val"),
    "annotation with _ in the name":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "project_id", value: "val"),
  }

  invalid_cases = {
    "Empty annotation name":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "", value: "val"),
    "Double slash":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a//b", value: "val"),
    "Nested Array":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a[2]/c", value: "val"),
    "Array element Access":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "a/b/c[2]", value: "val"),
    "- in annotation":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "project-id", value: "val"),
    ": in annotation":
      Authentication::ResourceRestrictions::ResourceRestriction.new(name: "project:id", value: "val")
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Valid Cases" do
    valid_cases.each do |description, restriction|
      context "#{description}" do
        it "works" do
          expect { restriction_name_validator.call(restriction: restriction) }.to_not raise_error
        end
      end
    end

    invalid_cases.each do |description, restriction|
      context "#{description}" do
        it "works" do
          expect { restriction_name_validator.call(restriction: restriction) }.to raise_error(Errors::Authentication::AuthnJwt::InvalidRestrictionName)
        end
      end
    end
  end
end
