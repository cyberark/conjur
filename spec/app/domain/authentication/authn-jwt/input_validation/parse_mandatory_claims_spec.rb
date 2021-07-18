# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims') do
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Input validation" do
    context "with empty claim name value value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: ""
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToParseMandatoryClaimsMissingInput)
      end
    end

    context "with nil claim name value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToParseMandatoryClaimsMissingInput)
      end
    end
  end

  context "Invalid format" do
    context "with invalid commas format" do
      context "when input with 1 comma value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: ","
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end

      context "when input with multiple commas value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: ",,,,,"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end

      context "when input with commas at start value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: ",claim1, claim2"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end

      context "when input with commas at end value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim1, claim2,"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end
    end

    context "with connected commas" do
      context "when input with multiple connected commas value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim1,, claim2"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end

      context "when input with multiple connected commas with spaces value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim1,   , claim2"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
        end
      end
    end
    
    context "with claims duplications values" do
      context "when input with connected duplicate claims value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim1, claim2,claim2, claim3"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormatContainsDuplication)
        end
      end

      context "when input with duplicate claims value at the start and at the end" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim1, claim2,claim3, claim1"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormatContainsDuplication)
        end
      end
    end

    context "with claim names with spaces" do
      context "when input with 1 claim name" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "claim      1"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
        end
      end

      context "when input with multiple claims " do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
            mandatory_claims: "valid, valid2   ,   claim1    rr, claim      1"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
        end
      end
    end
  end

  context "Valid format" do
    context "when input with 1 claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "claim1"
        )
      end

      it "returns a valid claims list" do
        expect(subject).to eql(["claim1"])
      end
    end

    context "when input with multiple valid claims values no spaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "claim1,claim2,claim3"
        )
      end

      it "returns a valid claims list" do
        expect(subject).to eql(%w[claim1 claim2 claim3])
      end
    end

    context "when input with multiple valid claims values and spaces at start" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "       claim1,claim2,claim3"
        )
      end

      it "returns a valid claims list" do
        expect(subject).to eql(%w[claim1 claim2 claim3])
      end
    end

    context "when input with multiple valid claims values and spaces at end" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "claim1,claim2,claim3     "
        )
      end

      it "returns a valid claims list" do
        expect(subject).to eql(%w[claim1 claim2 claim3])
      end
    end

    context "when input with multiple valid claims values and spaces in the middle" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "claim1,          claim2, claim3"
        )
      end

      it "returns a valid claims list" do
        expect(subject).to eql(%w[claim1 claim2 claim3])
      end
    end
  end

  context "Valid claim name" do
    context "when input with 1 invalid claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "1claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "when input with multiple invalid claims" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "1claim, 2claim, 3claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "when input with 1 invalid claim and multiple valid claims" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMandatoryClaims.new().call(
          mandatory_claims: "1claim, claim2, claim3"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end
  end
end

