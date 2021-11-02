# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::InputValidation::ValidateClaimName') do
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Input validation" do
    context "with empty claim name value value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: ""
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimMissingClaimName)
      end
    end

    context "with nil claim name value" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimMissingClaimName)
      end
    end
  end

  context "Invalid claim name value" do
    context "When claim name Starts with digit" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "9agfdsg"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name starts with forbidden character '%'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "%23$agfdsg"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name ends with forbidden character '#'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$agfdsg#"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name starts with forbidden character '.'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: ".invalid"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name contains forbidden character in the middle '!'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "a!c"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name is 1 dot character '.'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "."
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name contains 1 forbidden character '*'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "*"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name starts with spaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "   claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name ends with spaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "claim   "
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When claim name contains spaces" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "claim  name"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "when input has illegal [ character in claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "my[claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "when input has illegal [ ] characters in claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "my[1]claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When input has illegal - character in claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "my-claim"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end

    context "When input has illegal : character in claim name" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "a:"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName)
      end
    end
  end

  context "Valid claim name value" doב
    context "When claim name contains 1 allowed char 'F'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "F"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains 1 allowed char 'f'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "f"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains 1 allowed char '_'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "_"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains value with allowed char '/'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "a/a"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains value with multiple allowed chars '/'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "a/a/a/a"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains 1 allowed char '$'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains digits in the middle" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$2w"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name contains dots in the middle" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$...4.w"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end
    
    context "When claim name ends with dots" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$w..."
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name ends with digits" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new().call(
          claim_name: "$2w9"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  context "Claim name exists in deny list" do
    context "When claim name value is 'exp'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "exp"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end

    context "When claim name value is 'iat'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "iat"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end

    context "When claim name value is 'nbf'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "nbf"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end

    context "When claim name value is 'jti'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "jti"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end

    context "When claim name value is 'aud'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "aud"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end

    context "When claim name value is 'iss'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "iss"
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
      end
    end
  end

  context "Claim name is not exists in deny list" do
    context "When claim name value is 'sub'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "sub"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name value is substring of forbidden claim 'exp1'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "exp1"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "When claim name value is substring of forbidden claim '$exp'" do
      subject do
        ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
          deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
        ).call(
          claim_name: "$exp"
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
