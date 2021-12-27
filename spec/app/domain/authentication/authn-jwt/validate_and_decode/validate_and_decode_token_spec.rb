# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken') do

  let(:jwt_token_valid) { "valid token" }
  let(:authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: "dummy",
      service_id: "dummy",
      account: "dummy",
      username: "dummy",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    )
  }

  let(:mocked_create_signing_key_provider_failed) { double("MockedSigningKeyInterfaceFactoryFailed") }
  let(:mocked_create_signing_key_provider_always_succeed) { double("MockedSigningKeyInterfaceFactoryAlwaysSucceed") }
  let(:mocked_create_signing_key_provider_failed_on_1st_time) { double("MockedSigningKeyInterfaceFactoryFailedOn1") }
  let(:mocked_create_signing_key_provider_failed_on_2st_time) { double("MockedSigningKeyInterfaceFactoryFailedOn2") }

  let(:create_signing_key_provider_error) { "signing key interface factory error" }

  let(:mocked_fetch_signing_key_provider_always_succeed) { double("MockedFetchSigningKeyProviderAlwaysSucceed") }
  let(:mocked_fetch_signing_key_provider_failed_on_1st_time) { double("MockedFetchSigningKeyProviderFailedOn1") }
  let(:mocked_fetch_signing_key_provider_failed_on_2nd_time) { double("MockedFetchSigningKeyProviderFailedOn2") }

  let(:fetch_signing_key_1st_time_error) { "fetch signing key 1st time error" }
  let(:fetch_signing_key_2nd_time_error) { "fetch signing key 2nd time error" }

  let(:mocked_verify_and_decode_token_invalid) { double("MockedVerifyAndDecodeToken") }
  let(:mocked_verify_and_decode_token_succeed_on_1st_time) { double("MockedVerifyAndDecodeToken") }
  let(:mocked_verify_and_decode_token_succeed_on_2nd_time) { double("MockedVerifyAndDecodeToken") }
  let(:verify_and_decode_token_error) { "verify and decode token error" }
  let(:verify_and_decode_token_1st_time_error) { "verify and decode token 1st time error" }

  def valid_decoded_token(claims)
    token_dictionary = {}
    claims.each do |claim|
      token_dictionary[claim.name] = claim.value
    end

    token_dictionary
  end

  let(:valid_signing_key_uri) { "http://valid_signing_key_uri" }

  let(:jwks_from_1st_call) { " jwks from 1st call "}
  let(:jwks_from_2nd_call) { " jwks from 2nd call "}
  let(:verification_options_for_signature_only_1st_call) {
    {
      algorithms: Authentication::AuthnJwt::SUPPORTED_ALGORITHMS,
      jwks: jwks_from_1st_call
    }
  }

  let(:verification_options_for_signature_only_2nd_call) {
    {
      algorithms: Authentication::AuthnJwt::SUPPORTED_ALGORITHMS,
      jwks: jwks_from_2nd_call
    }
  }

  let(:mocked_fetch_jwt_claims_to_validate_valid) { double("MockedFetchJwtClaimsToValidateValid") }

  let(:valid_claim_name) { "valid-claim-name"}
  let(:valid_claim_name_not_exists_in_token) { "valid-claim-name-not-exists"}
  let(:valid_claim_value) { "valid claim value"}
  let(:valid_claim) {
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(
      name: valid_claim_name,
      value: valid_claim_value
    )
  }
  let(:claim_not_exists_in_token) {
    ::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(
      name: valid_claim_name_not_exists_in_token,
      value: valid_claim_value
    )
  }
  let(:claims_to_validate_valid)  { [valid_claim] }
  let(:claims_to_validate_not_exist_in_token)  { [claim_not_exists_in_token] }

  let(:mocked_get_verification_option_by_jwt_claim_valid) { double("MockedGetVerificationOptionByJwtClaimValid") }

  let(:verification_options_valid) { {opt: "valid"} }

  let(:valid_decoded_token_after_claims_validation) { "valid token after claims validation" }

  let(:mocked_fetch_jwt_claims_to_validate_invalid) { double("MockedFetchJwtClaimsToValidateInvalid") }
  let(:fetch_jwt_claims_to_validate_error) { "fetch jwt claims to validate error" }
  let(:mocked_fetch_jwt_claims_to_validate_with_empty_claims) { double("MockedFetchJwtClaimsToValidateValid") }
  let(:mocked_fetch_jwt_claims_to_validate_with_not_exist_claims_in_token) { double("MockedFetchJwtClaimsToValidateValid") }

  let(:mocked_get_verification_option_by_jwt_claim_invalid) { double("MockedGetVerificationOptionInvalid") }
  let(:get_verification_option_by_jwt_claim_error) { "get verification option by jwt claim error" }

  let(:mocked_verify_and_decode_token_failed_to_validate_claims) { double("MockedVerifyAndDecodeTokenFailedToValidateClaims") }
  let(:verify_and_decode_token_failed_to_validate_claims_error) { "verify and decode token failed to validate claims error" }
  let(:mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_not_updated) { double("MockedVerifyAndDecodeTokenSucceedToValidateClaims") }
  let(:mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_updated) { double("MockedVerifyAndDecodeTokenSucceedToValidateClaims") }

  before(:each) do
    allow(mocked_create_signing_key_provider_failed).to(
      receive(:call).and_raise(create_signing_key_provider_error)
    )

    allow(mocked_create_signing_key_provider_always_succeed).to(
      receive(:call).and_return(mocked_fetch_signing_key_provider_always_succeed)
    )

    allow(mocked_create_signing_key_provider_failed_on_1st_time).to(
      receive(:call).and_return(mocked_fetch_signing_key_provider_failed_on_1st_time)
    )

    allow(mocked_create_signing_key_provider_failed_on_2st_time).to(
      receive(:call).and_return(mocked_fetch_signing_key_provider_failed_on_2nd_time)
    )

    allow(mocked_fetch_signing_key_provider_always_succeed).to(
      receive(:call).with(
        force_fetch: false
      ).and_return(jwks_from_1st_call)
    )

    allow(mocked_fetch_signing_key_provider_always_succeed).to(
      receive(:call).with(
        force_fetch: true
      ).and_return(jwks_from_2nd_call)
    )

    allow(mocked_fetch_signing_key_provider_failed_on_1st_time).to(
      receive(:call).with(
        force_fetch: false
      ).and_raise(fetch_signing_key_1st_time_error)
    )

    allow(mocked_fetch_signing_key_provider_failed_on_2nd_time).to(
      receive(:call).with(
        force_fetch: false
      ).and_return(jwks_from_2nd_call)
    )

    allow(mocked_fetch_signing_key_provider_failed_on_2nd_time).to(
      receive(:call).with(
        force_fetch: true
      ).and_raise(fetch_signing_key_2nd_time_error)
    )

    allow(mocked_verify_and_decode_token_invalid).to(
      receive(:call).and_raise(verify_and_decode_token_error)
    )

    allow(mocked_verify_and_decode_token_succeed_on_1st_time).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call
      ).and_return(valid_decoded_token(claims_to_validate_valid))
    )

    allow(mocked_verify_and_decode_token_succeed_on_1st_time).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call.merge(verification_options_valid)
      ).and_return(valid_decoded_token_after_claims_validation)
    )

    allow(mocked_verify_and_decode_token_succeed_on_2nd_time).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call
      ).and_raise(verify_and_decode_token_1st_time_error)
    )

    allow(mocked_verify_and_decode_token_succeed_on_2nd_time).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_2nd_call
      ).and_return(valid_decoded_token(claims_to_validate_valid))
    )

    allow(mocked_verify_and_decode_token_succeed_on_2nd_time).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_2nd_call.merge(verification_options_valid)
      ).and_return(valid_decoded_token_after_claims_validation)
    )

    allow(mocked_fetch_jwt_claims_to_validate_valid).to(
      receive(:call).and_return(claims_to_validate_valid)
    )

    allow(mocked_get_verification_option_by_jwt_claim_valid).to(
      receive(:call).and_return(verification_options_valid)
    )

    allow(mocked_fetch_jwt_claims_to_validate_invalid).to(
      receive(:call).and_raise(fetch_jwt_claims_to_validate_error)
    )

    allow(mocked_fetch_jwt_claims_to_validate_with_empty_claims).to(
      receive(:call).and_return([])
    )

    allow(mocked_fetch_jwt_claims_to_validate_with_not_exist_claims_in_token).to(
      receive(:call).and_return(claims_to_validate_not_exist_in_token)
    )

    allow(mocked_get_verification_option_by_jwt_claim_invalid).to(
      receive(:call).and_raise(get_verification_option_by_jwt_claim_error)
    )

    allow(mocked_verify_and_decode_token_failed_to_validate_claims).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call
      ).and_return(valid_decoded_token(claims_to_validate_valid))
    )

    allow(mocked_verify_and_decode_token_failed_to_validate_claims).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call.merge(verification_options_valid)
      ).and_raise(verify_and_decode_token_failed_to_validate_claims_error)
    )

    allow(mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_not_updated).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call
      ).and_return(valid_decoded_token(claims_to_validate_valid))
    )

    allow(mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_not_updated).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call.merge(verification_options_valid)
      ).and_return(valid_decoded_token_after_claims_validation)
    )

    allow(mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_updated).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_1st_call
      ).and_raise(verify_and_decode_token_1st_time_error)
    )

    allow(mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_updated).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_2nd_call
      ).and_return(valid_decoded_token(claims_to_validate_valid))
    )

    allow(mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_updated).to(
      receive(:call).with(
        token_jwt: jwt_token_valid,
        verification_options: verification_options_for_signature_only_2nd_call.merge(verification_options_valid)
      ).and_return(valid_decoded_token_after_claims_validation)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'jwt_token' invalid input" do
    context "with nil value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new().call(
          authenticator_input: authenticator_input,
          jwt_token: nil
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingToken)
      end
    end

    context "with empty value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new().call(
          authenticator_input: authenticator_input,
          jwt_token: ""
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingToken)
      end
    end
  end

  context "Failed to fetch keys" do
    context "When error is during signing key factory call" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
          create_signing_key_provider: mocked_create_signing_key_provider_failed
        ).call(
          authenticator_input: authenticator_input,
          jwt_token: jwt_token_valid
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(create_signing_key_provider_error)
      end
    end

    context "When error is during fetching from provider" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
          create_signing_key_provider: mocked_create_signing_key_provider_failed_on_1st_time
        ).call(
          authenticator_input: authenticator_input,
          jwt_token: jwt_token_valid
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(fetch_signing_key_1st_time_error)
      end
    end
  end

  context "Validate token signature" do
    context "when 'jwt_token' with invalid signature" do
      context "and failed to fetch keys from provider" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
            verify_and_decode_token: mocked_verify_and_decode_token_invalid,
            create_signing_key_provider: mocked_create_signing_key_provider_failed_on_2st_time
          ).call(
            authenticator_input: authenticator_input,
            jwt_token: jwt_token_valid
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_signing_key_2nd_time_error)
        end
      end

      context "and succeed to fetch keys from provider" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
            verify_and_decode_token: mocked_verify_and_decode_token_invalid,
            create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
          ).call(
            authenticator_input: authenticator_input,
            jwt_token: jwt_token_valid
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(verify_and_decode_token_error)
        end
      end
    end

    context "when 'jwt_token' with valid signature" do
      context "and keys are not updated" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
            verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_2nd_time,
            fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
            get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_valid,
            create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
          ).call(
            authenticator_input: authenticator_input,
            jwt_token: jwt_token_valid
          )
        end

        it "returns decoded token value" do
          expect(subject).to eql(valid_decoded_token_after_claims_validation)
        end
      end

      context "and keys are updated" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
            verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_1st_time,
            fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
            get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_valid,
            create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
          ).call(
            authenticator_input: authenticator_input,
            jwt_token: jwt_token_valid
          )
        end

        it "returns decoded token value" do
          expect(subject).to eql(valid_decoded_token_after_claims_validation)
        end
      end
    end
  end

  context "Fetch enforced claims" do
    context "when token signature is valid" do
      context "and failed to fetch enforced claims" do
        subject do
          ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
            verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_1st_time,
            fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_invalid,
            create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
          ).call(
            authenticator_input: authenticator_input,
            jwt_token: jwt_token_valid
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_jwt_claims_to_validate_error)
        end
      end

      context "and succeed to fetch enforced claims" do
        context "with empty claims list to validate" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
              verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_1st_time,
              fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_with_empty_claims,
              create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
            ).call(
              authenticator_input: authenticator_input,
              jwt_token: jwt_token_valid
            )
          end

          it "returns decoded token value" do
            expect(subject).to eql(valid_decoded_token(claims_to_validate_valid))
          end
        end

        context "with mandatory claims which do not exist in token" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
              verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_1st_time,
              fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_with_not_exist_claims_in_token,
              create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
            ).call(
              authenticator_input: authenticator_input,
              jwt_token: jwt_token_valid
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingMandatoryClaim)
          end
        end

        context "and failed to get verification options" do
          subject do
            ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
              verify_and_decode_token: mocked_verify_and_decode_token_succeed_on_1st_time,
              fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
              get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_invalid,
              create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
            ).call(
              authenticator_input: authenticator_input,
              jwt_token: jwt_token_valid
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(get_verification_option_by_jwt_claim_error)
          end
        end
      end
    end
  end

  context "Validate token claims" do
    context "when token signature is valid" do
      context "when fetch enforced claims successfully" do
        context "when get verification options successfully" do
          context "and failed to validate claims" do
            subject do
              ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
                verify_and_decode_token: mocked_verify_and_decode_token_failed_to_validate_claims,
                fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
                get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_valid,
                create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
              ).call(
                authenticator_input: authenticator_input,
                jwt_token: jwt_token_valid
              )
            end

            it "raises an error" do
              expect { subject }.to raise_error(verify_and_decode_token_failed_to_validate_claims_error)
            end
          end

          context "and succeed to validate claims" do
            context "and keys are not updated" do
              subject do
                ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
                  verify_and_decode_token: mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_not_updated,
                  fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
                  get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_valid,
                  create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
                ).call(
                  authenticator_input: authenticator_input,
                  jwt_token: jwt_token_valid
                )
              end

              it "returns decoded token value" do
                expect(subject).to eql(valid_decoded_token_after_claims_validation)
              end
            end

            context "and keys are updated" do
              subject do
                ::Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new(
                  verify_and_decode_token: mocked_verify_and_decode_token_succeed_to_validate_claims_when_keys_updated,
                  fetch_jwt_claims_to_validate: mocked_fetch_jwt_claims_to_validate_valid,
                  get_verification_option_by_jwt_claim: mocked_get_verification_option_by_jwt_claim_valid,
                  create_signing_key_provider: mocked_create_signing_key_provider_always_succeed
                ).call(
                  authenticator_input: authenticator_input,
                  jwt_token: jwt_token_valid
                )
              end

              it "returns decoded token value" do
                expect(subject).to eql(valid_decoded_token_after_claims_validation)
              end
            end
          end
        end
      end
    end
  end
end
