# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne') do
  let(:right_email) { "admin@example.com" }
  let(:wrong_email) { "wrong@example.com" }
  let(:empty_email) { "" }
  let(:spaced_email) { "  " }
  let(:right_login) { "cucumber" }
  let(:wrong_login) { "tomato" }

  let(:decoded_token) {
    {
      "namespace_id" => "1",
      "namespace_path" => "root",
      "project_id" => "34",
      "project_path" => "root/test-proj",
      "user_id" => "1",
      "user_login" => right_login,
      "user_email" => right_email,
      "pipeline_id" => "1",
      "job_id" => "4",
      "ref" => "master",
      "ref_type" => "branch",
      "ref_protected" => "true",
      "jti" => "90c4414b-f7cf-4b98-9a4f-2c29f360e6d0",
      "iss" => "ec2-18-157-123-113.eu-central-1.compute.amazonaws.com",
      "iat" => 1619352275,
      "nbf" => 1619352270,
      "exp" => 1619355875,
      "sub" => "job_4"
    }
  }

  let(:aliased_claims) {
    {
      "identity" => "user_login",
      "machine_name" => "not_existing"
    }
  }

  let(:empty_aliased_claims) {
    {}
  }

  let(:existing_right_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_email", value: right_email)
  }

  let(:existing_wrong_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_email", value: wrong_email)
  }

  let(:non_existing_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "not_existing", value: wrong_email)
  }

  let(:empty_annotation_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "not_existing", value: "")
  }

  let(:spaced_annotation_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "not_existing", value: "    ")
  }

  let(:mapped_right_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_login", value: right_login)
  }

  let(:mapped_wrong_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "user_login", value: wrong_login)
  }

  let(:non_existing_mapped_restriction) {
    Authentication::ResourceRestrictions::ResourceRestriction.new(name: "machine_name", value: "test_machine")
  }
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "ValidateRestrictionsOneToOne" do
    context "Mapping is empty" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne.new(
          decoded_token: decoded_token,
          aliased_claims: empty_aliased_claims
        )
      end

      it "returns true when the restriction is for existing field and its value equals the token" do
        expect(subject.valid_restriction?(existing_right_restriction)).to eql(true)
      end

      it "return false when the restriction is for existing field but the value is different then the token" do
        expect(subject.valid_restriction?(existing_wrong_restriction)).to eql(false)
      end

      it "raises JwtTokenClaimIsMissing when restriction is not in the decoded token" do
        expect { subject.valid_restriction?(non_existing_restriction) }.to raise_error(
                                                                             Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                                                                             /.*'not_existing'.*/
                                                                           )
      end

      it "raises EmptyAnnotationGiven when annotation is empty" do
        expect { subject.valid_restriction?(empty_annotation_restriction) }.to raise_error(Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven)
      end

      it "raises EmptyAnnotationGiven when annotation is just spaces" do
        expect { subject.valid_restriction?(spaced_annotation_restriction) }.to raise_error(Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven)
      end
    end

    context "Mapping is not empty" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne.new(
          decoded_token: decoded_token,
          aliased_claims: aliased_claims
        )
      end

      it "returns true when the restriction is for existing field and its value equals the token" do
        expect(subject.valid_restriction?(mapped_right_restriction)).to eql(true)
      end

      it "return false when the restriction is for existing field but the value is different then the token" do
        expect(subject.valid_restriction?(mapped_wrong_restriction)).to eql(false)
      end

      it "raises JwtTokenClaimIsMissing when restriction is not in the decoded token" do
        expect { subject.valid_restriction?(non_existing_mapped_restriction) }.to raise_error(
                                                                             Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                                                                             /.*'not_existing \(annotation\: machine_name\)'.*/
                                                                           )
      end
    end
  end
end
