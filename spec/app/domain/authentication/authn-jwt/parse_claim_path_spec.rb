# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::ParseClaimPath) do

  context "Invalid claim path" do
    context "When one of claim names Starts with digit" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "kuku/9agfdsg"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name starts with forbidden character '['" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "kuku[12]/[23$agfdsg[33]"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name ends with forbidden character '#'" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "$agfdsg#[66]"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name contains forbidden character in the middle '!'" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim[4][56]/a!c/wd"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name starts from '/'" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "/claim[4][56]"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name ends with '/'" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "dflk[34]/claim[4][56]/"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When claim name contains only index part" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim/[4]/kuku"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When index part contains letters" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim/kuku[kl]"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end

    context "When index part is empty" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim/kuku[]/claim1"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidClaimPath)
      end
    end
  end

  context "Valid claim path" do
    context "Single claim name" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim"
        )
      end

      it "returns a valid array" do
        expect(subject).to eql(["claim"])
      end
    end

    context "Single claim name with index" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim[1]"
        )
      end

      it "returns a valid array" do
        expect(subject).to eql(["claim", 1])
      end
    end

    context "Single claim name with indexes" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim2[1][23][456]"
        )
      end

      it "returns a valid array" do
        expect(subject).to eql(["claim2", 1, 23, 456])
      end
    end

    context "Multiple claims with indexes" do
      subject do
        ::Authentication::AuthnJwt::ParseClaimPath.new.call(
          claim: "claim1[1]/claim2/claim3[23][456]/claim4"
        )
      end

      it "returns a valid array" do
        expect(subject).to eql([
                                 "claim1",
                                 1,
                                 "claim2",
                                 "claim3",
                                 23,
                                 456,
                                 "claim4"
                               ])
      end
    end
  end
end
