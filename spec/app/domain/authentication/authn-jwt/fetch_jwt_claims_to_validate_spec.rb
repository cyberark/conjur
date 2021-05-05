# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::FetchJwtClaimsToValidate') do

  RSpec::Matchers.define :eql_claims_list do |expected|
    match do |actual|
      return false unless actual.length == expected.length
      actual_sorted = actual.sort_by {|obj| obj.name}
      expected_sorted = expected.sort_by {|obj| obj.name}

      actual_sorted.length.times do |index|
        return false unless actual_sorted[index].name == expected_sorted[index].name &&
          actual_sorted[index].value == expected_sorted[index].value
      end

      return true
    end
  end

  let(:all_supported_optional_claims) { %w[iss exp nbf iat].freeze }
  let(:iss_claim_valid_value) { "iss claim valid value" }
  let(:token_claim_value) { "value" }

  def jwt_claims_to_validate_list_with_values(optional_claims)
    jwt_claims_to_validate_list = []
    optional_claims.each do |optional_claim|
      jwt_claims_to_validate_list.push(::Authentication::AuthnJwt::JwtClaim.new(name: optional_claim, value: claim_value(optional_claim)))
    end

    jwt_claims_to_validate_list
  end

  def claim_value(optional_claim)
    if optional_claim == 'iss'
      return iss_claim_valid_value
    end

    nil
  end

  def token(optional_claims)
    token_dictionary = {}
    optional_claims.each do |optional_claim|
      token_dictionary[optional_claim] = token_claim_value
    end

    token_dictionary
  end

  let(:mocked_fetch_issuer_value_valid) { double("MockedFetchIssuerValueValid") }
  let(:mocked_authentication_parameters_with_all_supported_optional_claims_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_just_iss_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_just_exp_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_just_nbf_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_just_iat_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_no_optional_claims_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_empty_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_all_except_iss_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_all_except_exp_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_all_except_nbf_claim_token) { double("MockedAuthenticationParameters") }
  let(:mocked_authentication_parameters_with_all_except_iat_claim_token) { double("MockedAuthenticationParameters") }

  let(:invalid_issuer_configuration_error) { "invalid issuer configuration error" }
  let(:mocked_fetch_issuer_value_invalid_configuration) { double("MockedFetchIssuerValueInvalid") }

  before(:each) do
    allow(mocked_fetch_issuer_value_valid).to(
      receive(:call).and_return(iss_claim_valid_value)
    )

    allow(mocked_authentication_parameters_with_all_supported_optional_claims_token).to(
      receive(:decoded_token).and_return(token(all_supported_optional_claims))
    )

    allow(mocked_authentication_parameters_with_just_iss_claim_token).to(
      receive(:decoded_token).and_return(token(%w[iss].freeze))
    )

    allow(mocked_authentication_parameters_with_just_exp_claim_token).to(
      receive(:decoded_token).and_return(token(%w[exp].freeze))
    )

    allow(mocked_authentication_parameters_with_just_nbf_claim_token).to(
      receive(:decoded_token).and_return(token(%w[nbf].freeze))
    )

    allow(mocked_authentication_parameters_with_just_iat_claim_token).to(
      receive(:decoded_token).and_return(token(%w[iat].freeze))
    )

    allow(mocked_authentication_parameters_with_all_except_iss_claim_token).to(
      receive(:decoded_token).and_return(token(%w[exp nbf iat].freeze))
    )

    allow(mocked_authentication_parameters_with_all_except_exp_claim_token).to(
      receive(:decoded_token).and_return(token(%w[iss nbf iat].freeze))
    )

    allow(mocked_authentication_parameters_with_all_except_nbf_claim_token).to(
      receive(:decoded_token).and_return(token(%w[iss exp iat].freeze))
    )

    allow(mocked_authentication_parameters_with_all_except_iat_claim_token).to(
      receive(:decoded_token).and_return(token(%w[iss exp nbf].freeze))
    )

    allow(mocked_authentication_parameters_with_no_optional_claims_token).to(
      receive(:decoded_token).and_return(token(%w[not_supported1].freeze))
    )

    allow(mocked_authentication_parameters_with_empty_token).to(
      receive(:decoded_token).and_return({})
    )

    allow(mocked_fetch_issuer_value_invalid_configuration).to(
      receive(:call).and_raise(invalid_issuer_configuration_error)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "JWT decided token input" do
    context "with all supported optional claims: (iss, exp, nbf, iat)" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_supported_optional_claims_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(all_supported_optional_claims))
        end
      end
    end

    context "with just iss claim" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_just_iss_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iss].freeze))
        end
      end

      context "with invalid issuer variable configuration" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_just_iss_claim_token
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(invalid_issuer_configuration_error)
        end
      end
    end

    context "with just exp claim" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_just_exp_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp].freeze))
        end
      end
    end

    context "with just nbf claim" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_just_nbf_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[nbf].freeze))
        end
      end
    end

    context "with just iat claim" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_just_iat_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iat].freeze))
        end
      end
    end

    context "with empty token (should not happened)" do
      subject do
        ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
          fetch_issuer_value: mocked_fetch_issuer_value_valid
        ).call(
          authentication_parameters: mocked_authentication_parameters_with_empty_token
        )
      end

      it "returns jwt claims to validate list" do
        expect(subject).to eql([])
      end
    end

    context "with none of supported optional claims" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_no_optional_claims_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql([])
        end
      end

      context "with invalid issuer variable configuration" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_no_optional_claims_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql([])
        end
      end
    end

    context "with all except iss: (exp, nbf, iat)" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_except_iss_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf iat].freeze))
        end
      end

      context "with invalid issuer variable configuration" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_except_iss_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf iat].freeze))
        end
      end
    end

    context "with all except exp: (iss, nbf, iat)" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_except_exp_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iss nbf iat].freeze))
        end
      end
    end

    context "with all except nbf: (iss, exp, iat)" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_except_nbf_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iss exp iat].freeze))
        end
      end
    end

    context "with all except iat: (iss, exp, nbf)" do
      context "with valid issuer variable configuration in authenticator policy" do
        subject do
          ::Authentication::AuthnJwt::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: mocked_authentication_parameters_with_all_except_iat_claim_token
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iss exp nbf].freeze))
        end
      end
    end
  end
end
