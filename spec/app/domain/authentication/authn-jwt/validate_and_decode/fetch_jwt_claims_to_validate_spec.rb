# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate') do
  RSpec::Matchers.define(:eql_claims_list) do |expected|
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

  let(:iss_claim_valid_value) { "iss claim valid value" }
  let(:token_claim_value) { "value" }

  def jwt_claims_to_validate_list_with_values(claims)
    jwt_claims_to_validate_list = []
    claims.each do |claim|
      jwt_claims_to_validate_list.push(::Authentication::AuthnJwt::ValidateAndDecode::JwtClaim.new(name: claim, value: claim_value(claim)))
    end

    jwt_claims_to_validate_list
  end

  def claim_value(claim)
    if claim == 'iss'
      return iss_claim_valid_value
    end

    nil
  end

  def token(claims)
    token_dictionary = {}
    claims.each do |claim|
      token_dictionary[claim] = token_claim_value
    end

    token_dictionary
  end

  let(:authentication_parameters) do
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: Authentication::AuthenticatorInput.new(
        authenticator_name: "dummy",
        service_id: "dummy",
        account: "dummy",
        username: "dummy",
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      jwt_token: nil
    )
  end

  let(:mocked_fetch_issuer_value_valid) { double("MockedFetchIssuerValueValid") }

  let(:invalid_issuer_configuration_error) { "invalid issuer configuration error" }
  let(:mocked_fetch_issuer_value_invalid_configuration) { double("MockedFetchIssuerValueInvalid") }

  before(:each) do
    allow(mocked_fetch_issuer_value_valid).to(
      receive(:call).and_return(iss_claim_valid_value)
    )

    allow(mocked_fetch_issuer_value_invalid_configuration).to(
      receive(:call).and_raise(invalid_issuer_configuration_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "JWT decoded token input" do
    context "with mandatory claims (exp)" do
      context "and with all supported optional claims: (iss, nbf, iat)" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[iss exp nbf iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[iss exp nbf iat].freeze))
          end
        end
      end

      context "and with iss claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp iss].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss].freeze))
          end
        end

        context "with invalid issuer variable configuration" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp iss].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(invalid_issuer_configuration_error)
          end
        end
      end

      context "and with nbf claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp nbf].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf].freeze))
          end
        end
      end

      context "and with iat claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iat].freeze))
          end
        end
      end

      context "with none of supported optional claims" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp].freeze))
          end
        end

        context "with invalid issuer variable configuration" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp].freeze))
          end
        end
      end

      context "with all except iss: (exp, nbf, iat)" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp nbf iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf iat].freeze))
          end
        end

        context "with invalid issuer variable configuration" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp nbf iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf iat].freeze))
          end
        end
      end

      context "with all except nbf: (exp, iss, iat)" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp iss iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss iat].freeze))
          end
        end
      end

      context "with all except iat: (exp ,iss, nbf)" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[exp iss nbf].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss nbf].freeze))
          end
        end
      end
    end

    context "without mandatory claims (exp)" do
      context "and with all supported optional claims: (iss, nbf, iat)" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[iss nbf iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss nbf iat].freeze))
          end
        end
      end
      context "with invalid issuer variable configuration" do
        subject do
          authentication_parameters.decoded_token = token(%w[iss nbf iat].freeze)

          ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
            fetch_issuer_value: mocked_fetch_issuer_value_valid
          ).call(
            authentication_parameters: authentication_parameters
          )
        end

        it "returns jwt claims to validate list" do
          expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss nbf iat].freeze))
        end
      end

      context "and with iss claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[iss].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iss].freeze))
          end
        end

        context "with invalid issuer variable configuration" do
          subject do
            authentication_parameters.decoded_token = token(%w[iss].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_invalid_configuration
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(invalid_issuer_configuration_error)
          end
        end
      end

      context "and with nbf claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[nbf].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp nbf].freeze))
          end
        end
      end

      context "and with iat claim" do
        context "with valid issuer variable configuration in authenticator policy" do
          subject do
            authentication_parameters.decoded_token = token(%w[iat].freeze)

            ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
              fetch_issuer_value: mocked_fetch_issuer_value_valid
            ).call(
              authentication_parameters: authentication_parameters
            )
          end

          it "returns jwt claims to validate list" do
            expect(subject).to eql_claims_list(jwt_claims_to_validate_list_with_values(%w[exp iat].freeze))
          end
        end
      end
    end

    context "with empty token (should not happened)" do
      subject do
        authentication_parameters.decoded_token = token(%w[].freeze)

        ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
          fetch_issuer_value: mocked_fetch_issuer_value_valid
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingToken)
      end
    end

    context "with nil token (should not happened)" do
      subject do
        authentication_parameters.decoded_token = nil

        ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new(
          fetch_issuer_value: mocked_fetch_issuer_value_valid
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingToken)
      end
    end
  end
end
