# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::InputValidation::ValidateClaimName') do
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  let(:claim_name_validator) {
    ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new
  }

  let(:deny_list_claim_name_validator) {
    ::Authentication::AuthnJwt::InputValidation::ValidateClaimName.new(
      deny_claims_list_value: ::Authentication::AuthnJwt::CLAIMS_DENY_LIST
    )
  }

  invalid_cases = {
    "When claim value is empty": ["", Errors::Authentication::AuthnJwt::FailedToValidateClaimMissingClaimName],
    "When claim is nil": [nil, Errors::Authentication::AuthnJwt::FailedToValidateClaimMissingClaimName],
    "When claim name Starts with digit": ["9agfdsg", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name starts with forbidden character '%'": ["%23$agfdsg", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name ends with forbidden character '#'": ["$agfdsg#", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name starts with forbidden character '.'": [".invalid", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name is 1 dot character '.'": [".", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name is just 1 forbidden character '*'": ["*", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '*'": ["a*b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '-": ["a-b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '%'": ["a%b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '!'": ["a!b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '('": ["a(b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '&'": ["a&b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '@'": ["a@b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '^'": ["a^b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '~'": ["a~b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '\\'": ["a\\b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '+'": ["a+b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains 1 forbidden character '='": ["a=b", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name starts with spaces": ["   claim", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name ends with spaces": ["claim   ", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When claim name contains spaces": ["claim  name", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When input has illegal [ character in claim name": ["my[claim", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When input has illegal [ ] characters in claim name": ["my[1]claim", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When input has illegal - character in claim name": ["my-claim", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName],
    "When input has illegal : character in claim name": ["a:", Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName]
  }

  valid_cases = {
    "When claim name contains 1 allowed char 'F'": "F",
    "When claim name contains 1 allowed char 'f'": "f",
    "When claim name contains 1 allowed char '_'": "_",
    "When claim name contains value with allowed char '/'": "a/a",
    "When claim name contains value with multiple allowed chars '/'": "a/a/a/a",
    "When claim name contains 1 allowed char '$'": "$",
    "When claim name contains digits in the middle": "$2w",
    "When claim name contains dots in the middle": "$...4.w",
    "When claim name ends with dots": "$w...",
    "When claim name ends with digits": "$2w9",
    "When claim name contains allowed character '|'": "a|b"
  }

  deny_list_cases = {
    "When claim name value is 'exp'": "exp",
    "When claim name value is 'iat'": "iat",
    "When claim name value is 'nbf'": "nbf",
    "When claim name value is 'jti'": "jti",
    "When claim name value is 'aud'": "aud",
    "When claim name value is 'iss'": "iss"
  }

  not_in_deny_list_cases = {
    "When claim name value is 'sub'": "sub",
    "When claim name value is substring of forbidden claim 'exp1'": "exp1",
    "When claim name value is substring of forbidden claim '$exp'": "$exp"
  }

  context "Input validation" do
    context "Invalid examples" do
      invalid_cases.each do |description, (claim_name, error) |
        context "#{description}" do
          it "raises an error" do
            expect { claim_name_validator.call(claim_name: claim_name) }.to raise_error(error)
          end
        end
      end
    end

    context "Valid examples" do
      valid_cases.each do |description, claim_name|
        context "#{description}" do
          it "does not raise error" do
            expect { claim_name_validator.call(claim_name: claim_name) }.not_to raise_error
          end
        end
      end
    end

    context "Claim name exists in deny list" do
      deny_list_cases.each do |description, claim_name|
        context "#{description}" do
          it "raises an error" do
            expect { deny_list_claim_name_validator.call(claim_name: claim_name) }.
              to raise_error(Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList)
          end
        end
      end
    end

    context "Claim name is not exists in deny list" do
      not_in_deny_list_cases.each do |description, claim_name|
        context "#{description}" do
          it "does not raise error" do
            expect { deny_list_claim_name_validator.call(claim_name: claim_name) }.not_to raise_error
          end
        end
      end
    end
  end
end
