# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim') do
  let(:iss_claim_valid_value) { "iss claim valid value" }
  let(:unsupported_claim_name) { "unsupported-claim-name" }
  let(:valid_exp_verification_option) { {} }
  let(:valid_nbf_verification_option) { {} }
  let(:valid_iat_verification_option) { { verify_iat: true } }
  let(:valid_iss_verification_option) { { iss: iss_claim_valid_value, verify_iss: true } }
  let(:iss_claim_empty_value) do
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(name: "iss", value: "")
  end
  let(:iss_claim_nil_value) do
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(name: "iss", value: "")
  end

  def claim_value(claim_name)
    if claim_name == "iss"
      return iss_claim_valid_value
    end

    nil
  end

  def claim(claim_name)
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(name: claim_name, value: claim_value(claim_name))
  end

  let(:empty_claim) do
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(name: "", value: "")
  end

  before(:each) do
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'jwt_claim' input" do
    context "with nil value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
          jwt_claim: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingClaim)
      end
    end

    context "with empty name value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
          jwt_claim: empty_claim
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::UnsupportedClaim)
      end
    end

    context "with unsupported name value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
          jwt_claim: claim(unsupported_claim_name)
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::UnsupportedClaim)
      end
    end

    context "with supported name value" do
      context "with 'exp' name value" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
            jwt_claim: claim("exp")
          )
        end

        it "returns verification option value" do
          expect(subject).to eq(valid_exp_verification_option)
        end
      end

      context "with 'nbf' name value" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
            jwt_claim: claim("nbf")
          )
        end

        it "returns verification option value" do
          expect(subject).to eq(valid_nbf_verification_option)
        end
      end

      context "with 'iat' name value" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
            jwt_claim: claim("iat")
          )
        end

        it "returns verification option value" do
          expect(subject).to eq(valid_iat_verification_option)
        end
      end

      context "with 'iss' name value" do
        context "with empty claim value" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
              jwt_claim: iss_claim_empty_value
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingClaimValue)
          end
        end

        context "with nil claim value" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
              jwt_claim: iss_claim_nil_value
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingClaimValue)
          end
        end

        context "with claim value" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::GetVerificationOptionByJwtClaim.new.call(
              jwt_claim: claim("iss")
            )
          end

          it "returns verification option value" do
            expect(subject).to eq(valid_iss_verification_option)
          end
        end
      end
    end
  end
end
