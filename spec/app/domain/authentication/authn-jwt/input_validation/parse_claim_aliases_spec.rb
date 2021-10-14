# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::InputValidation::ParseClaimAliases') do
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Input validation" do
    context "with empty claim name value value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: ""
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesMissingInput)
      end
    end

    context "with nil claim name value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesMissingInput)
      end
    end

    context "when input is whitespaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: "  \t \n  "
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesMissingInput)
      end
    end
  end

  context "Invalid format" do
    context "with invalid list format" do
      context "when input is 1 coma" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: ","
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty)
        end
      end

      context "when input is only comas" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: ",,,,,"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty)
        end
      end


      context "when input contains blank alias value" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,   , b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty)
        end
      end
    end

    context "with invalid alias tuple format" do
      context "when alias tuple only contains delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,  :  ,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat)
        end
      end

      context "when alias tuple has no delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,value,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat)
        end
      end

      context "when alias tuple has more than one delimiter" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,x:y:z,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat)
        end
      end

      context "when alias tuple left side is empty" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,:R,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat)
        end
      end

      context "when alias tuple right side is empty" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,L:,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasInvalidFormat)
        end
      end
    end

    context "with invalid claim format" do
      context "when annotation name contains illegal character" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,annota tion:claim,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::ClaimAliasInvalidClaimFormat,
                                  /.*FailedToValidateClaimForbiddenClaimName: CONJ00104E.*/
                                )
        end
      end

      context "when claim name contains illegal character" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,annotation:cla#im,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::ClaimAliasInvalidClaimFormat,
                                  /.*FailedToValidateClaimForbiddenClaimName: CONJ00104E.*/
                                )
        end
      end
    end

    context "with denied claims" do
      context "when annotation name is in deny list" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "a:b,iss:claim"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::ClaimAliasInvalidClaimFormat,
                                  /.*FailedToValidateClaimClaimNameInDenyList: CONJ00105E.*/
                                )
        end
      end

      context "when claim name is in deny list" do
        subject do
          ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
            claim_aliases: "annotation:jti,b:c"
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::ClaimAliasInvalidClaimFormat,
                                  /.*FailedToValidateClaimClaimNameInDenyList: CONJ00105E.*/
                                )
        end
      end
    end
  end

  context "Duplication" do
    context "with duplication in annotation names" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: "a:b,a:c"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError,
                                /.*annotation name.*'a'.*/
                              )
      end
    end

    context "with duplication in claim names" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: "x:z,y:z"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError,
                                /.*claim name.*'z'.*/
                              )
      end
    end
  end

  context "Valid format" do
    context "when input with 1 alias statement" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: "annotation:claim"
        )
      end

      it "returns a valid alias hash" do
        expect(subject).to eql({"annotation" => "claim"})
      end
    end

    context "when input with multiple alias statements" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new().call(
          claim_aliases: "name1:\tname2,\nname2:\tname3,\nname3:name1"
        )
      end

      it "returns a valid alias hash" do
        expect(subject).to eql({
                                 "name1" => "name2",
                                 "name2" => "name3",
                                 "name3" => "name1"
                               })
      end
    end
  end
end

