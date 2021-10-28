# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsIncluded') do
  let(:decoded_token) {
    {
      "claim1" => %w[a b],
      "claim2" => %w[c d],
      "claim3" => %w[a b c],
      "claim4" => %w[a b],
      "claim5" => %w[a b b],
      "claim6" => %w[a b],
      "claim7" => "a",
      "claim8" => %w[a],
    }
  }

  let(:aliased_claims) {
    {
      "case1" => "claim1",
      "case2" => "claim2",
      "case3" => "claim3",
      "case4" => "claim4",
      "case5" => "claim5",
      "case6" => "claim6",
      "case7" => "claim7",
      "case8" => "claim8",
      "wrong" => "wrong_mapping"
    }
  }

  let(:empty_aliased_claims) {
    {}
  }

  let(:aliased_validator) {
    ::Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsIncluded.new(decoded_token: decoded_token,
                                                                                        aliased_claims: aliased_claims)
  }

  let(:non_aliased_validator) {
    ::Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsIncluded.new(decoded_token: decoded_token,
                                                                                        aliased_claims: empty_aliased_claims)
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  aliased_validator_examples = {
    "Similar lists in token and annotation":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case1", value: "[\"a\", \"b\"]"),
       true],
    "Totally different annotation and token lists":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case2", value: "[\"a\", \"b\"]"),
       false],
    "Token includes values in annotations and have additional one":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case3", value: "[\"a\", \"b\"]"),
       true],
    "One of the annotations is not in the token":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case4", value: "[\"a\", \"b\", \"c\"]"),
       false],
    "Element in host annotation appears twice in token value":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case5", value: "[\"a\", \"b\"]"),
       true]
  }

  non_aliased_validator_examples = {
    "Similar lists in token and annotation":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "claim1", value: "[\"a\", \"b\"]"),
       true],
    "Totally different annotation and token lists":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "claim2", value: "[\"a\", \"b\"]"),
       false],
    "Token includes values in annotations and have additional one":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "claim3", value: "[\"a\", \"b\"]"),
       true],
    "One of the annotations is not in the token":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "claim4", value: "[\"a\", \"b\", \"c\"]"),
       false],
    "Element in host annotation appears twice in token value":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "claim5", value: "[\"a\", \"b\"]"),
       true]
  }

  invalid_examples = {
    "wrong mapping":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "wrong", value: "[\"a\", \"b\"]"),
       Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing],
    "missing claim":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "missing", value: "[\"a\", \"b\"]"),
       Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing],
    "array of two values in token and non array in annotation":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case6", value: "a"),
       Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType],
    "array of single value in annotation and non array in token":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case7", value: "[\"a\"]"),
       Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType],
    "array of single value in token and non array in annotation":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "case8", value: "a"),
       Errors::Authentication::ResourceRestrictions::InconsistentHostAnnotationType],
    "empty annotation given":
      [Authentication::ResourceRestrictions::ResourceRestriction.new(name: "aaa", value: ""),
       Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven]
  }

  context "Valid Examples" do
    context "Validator with aliases" do
      aliased_validator_examples.each do |description, (restriction, output)|
        context "#{description}" do
          it "works" do
            expect(aliased_validator.valid_restriction?(restriction)).to eql(output)
          end
        end
      end
    end

    context "Validator without aliases" do
      non_aliased_validator_examples.each do |description, (restriction, output)|
        context "#{description}" do
          it "works" do
            expect(non_aliased_validator.valid_restriction?(restriction)).to eql(output)
          end
        end
      end
    end
  end

  context "Invalid Examples" do
    invalid_examples.each do |description, (restriction, error)|
      context "#{description}" do
        it "throws error" do
          expect { aliased_validator.valid_restriction?(restriction) }.to raise_error(error)
        end
      end
    end
  end
end
