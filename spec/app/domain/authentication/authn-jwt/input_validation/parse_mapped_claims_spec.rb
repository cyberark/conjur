# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::InputValidation::ParseMappedClaims') do
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Input validation" do
    context "with empty claim name value value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: ""
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsMissingInput)
      end
    end

    context "with nil claim name value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsMissingInput)
      end
    end

    context "when input is whitespaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: "  \t \n  "
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsMissingInput)
      end
    end
  end

  context "Invalid format" do
    context "with invalid list format" do
      context "when input is 1 coma" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: ","
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsBlankOrEmpty)
        end
      end

      context "when input is only comas" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: ",,,,,"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsBlankOrEmpty)
        end
      end


      context "when input contains blank mapping value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,   , b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimsBlankOrEmpty)
        end
      end
    end

    context "with invalid mapping tuple format" do
      context "when mapping tuple only contains delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,  :  ,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimInvalidFormat)
        end
      end

      context "when mapping tuple has no delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,value,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimInvalidFormat)
        end
      end

      context "when mapping tuple has more than one delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,x:y:z,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimInvalidFormat)
        end
      end

      context "when mapping tuple left side is empty" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,:R,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimInvalidFormat)
        end
      end

      context "when mapping tuple right side is empty" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,L:,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappedClaimInvalidFormat)
        end
      end
    end

    context "with invalid claim format" do
      context "when annotation name contains illegal character" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,annota tion:claim,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::MappedClaimInvalidClaimFormat,
                                  /.*FailedToValidateClaimForbiddenClaimName: CONJ00104E.*/
                                )
        end
      end

      context "when claim name contains illegal character" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,annotation:cla#im,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::MappedClaimInvalidClaimFormat,
                                  /.*FailedToValidateClaimForbiddenClaimName: CONJ00104E.*/
                                )
        end
      end
    end

    context "with denied claims" do
      context "when annotation name is in deny list" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "a:b,iss:claim"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::MappedClaimInvalidClaimFormat,
                                  /.*FailedToValidateClaimClaimNameInDenyList: CONJ00105E.*/
                                )
        end
      end

      context "when claim name is in deny list" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
            mapped_claims: "annotation:jti,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::MappedClaimInvalidClaimFormat,
                                  /.*FailedToValidateClaimClaimNameInDenyList: CONJ00105E.*/
                                )
        end
      end
    end
  end

  context "Duplication" do
    context "with duplication in annotation names" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: "a:b,a:c"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::MappedClaimDuplicationError,
                                /.*annotation name.*'a'.*/
                              )
      end
    end

    context "with duplication in claim names" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: "x:z,y:z"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::MappedClaimDuplicationError,
                                /.*claim name.*'z'.*/
                              )
      end
    end
  end

  context "Valid format" do
    context "when input with 1 mapping statement" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: "annotation:claim"
        )
      end

      it "returns a valid mapping hash" do
        expect(subject).to eql({"annotation" => "claim"})
      end
    end

    context "when input with multiple mapping statements" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseMappedClaims.new().call(
          mapped_claims: "name1:\tname2,\nname2:\tname3,\nname3:name1"
        )
      end

      it "returns a valid mapping hash" do
        expect(subject).to eql({
                                 "name1" => "name2",
                                 "name2" => "name3",
                                 "name3" => "name1"
                               })
      end
    end
  end
end

