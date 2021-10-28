# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider') do
  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }
  let(:token_identity) { 'token-identity' }
  let(:token_app_property_secret_value) { 'sub' }
  let(:token_app_property_secret_value_is_array) { 'actions' }
  let(:token_app_property_nested_from_hash_value) { 'nested/single' }
  let(:token_app_property_nested_from_array_value) { 'nested/array[0]' }
  let(:decoded_token) {
    {
      "namespace_id" => "1",
      "namespace_path" => "root",
      "project_id" => "34",
      "project_path" => "root/test-proj",
      "user_id" => "1",
      "user_login" => "cucumber",
      "user_email" => "admin@example.com",
      "pipeline_id" => "1",
      "job_id" => "4",
      "ref" => "master",
      "ref_type" => "branch",
      "ref_protected" => "true",
      "jti" => "90c4414b-f7cf-4b98-9a4f-2c29f360e6d0",
      "iss" => "ec2-18-157-123-113.eu-central-1.compute.amazonaws.com",
      "iat" => 1619352275,
      "nbf" => 1619352270,
      "exp" => 1619355875,
      "sub" => token_identity,
      "actions" => %w[HEAD GET POST PUT DELETE],
      "nested" => {
        "single" => "n_value",
        "array" => %w[a_value_1 a_value_2 a_value_3]
      }
    }
  }

  let(:jwt_authenticator_input) {
    Authentication::AuthnJwt::JWTAuthenticatorInput.new(
      authenticator_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: "dummy_identity",
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      decoded_token: nil
    )
  }

  let(:mocked_valid_secrets) {
    {
      "token-app-property" => token_app_property_secret_value
    }
  }

  let(:mocked_valid_secret_value_points_to_array) {
    {
      "token-app-property" => token_app_property_secret_value_is_array
    }
  }

  let(:mocked_valid_secret_hash) {
    {
      "token-app-property" => token_app_property_nested_from_hash_value
    }
  }

  let(:mocked_valid_secret_array) {
    {
      "token-app-property" => token_app_property_nested_from_array_value
    }
  }

  let(:mocked_valid_secrets_which_missing_in_token) {
    {
      "token-app-property" => "missing"
    }
  }

  let(:token_app_property_resource_name) { ::Authentication::AuthnJwt::TOKEN_APP_PROPERTY_VARIABLE }
  let(:identity_path_resource_name) { ::Authentication::AuthnJwt::IDENTITY_PATH_RESOURCE_NAME }
  let(:mocked_authenticator_secret_not_exists) { double("Mocked authenticator secret not exists")  }
  let(:mocked_authenticator_secret_exists) { double("Mocked authenticator secret exists") }
  let(:mocked_resource) { double("MockedResource") }
  let(:non_existing_field_name) { "non existing field name" }

  let(:mocked_fetch_authenticator_secrets_exist_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_value_points_to_array)  {  double("MochedFetchAuthenticatorSecretsPointsToArray") }
  let(:mocked_fetch_authenticator_secrets_value_hash) { double("MochedFetchAuthenticatorSecretsHash") }
  let(:mocked_fetch_authenticator_secrets_value_array) { double("MochedFetchAuthenticatorSecretsArray") }
  let(:mocked_fetch_authenticator_secrets_which_missing_in_token) {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:required_secret_missing_error) { "required secret missing error" }
  let(:required_identity_path_secret_missing_error) { "required secret missing error" }
  let(:mocked_fetch_required_secrets_token_app_with_value_identity_path_empty) {  double("MockedFetchRequiredSecrets") }
  let(:missing_claim_secret_value) { "not found claim" }
  let(:mocked_fetch_identity_path_failed) { double("MockedFetchIdentityPathFailed") }
  let(:fetch_identity_path_missing_error) { "fetch identity fetch missing error" }
  let(:mocked_fetch_identity_path_valid_empty_path) { double("MockedFetchIdentityPathValid") }
  let(:identity_path_valid_empty_path) { ::Authentication::AuthnJwt::IDENTITY_PATH_DEFAULT_VALUE }
  let(:mocked_fetch_identity_path_valid_value) { double("MockedFetchIdentityPathValid") }
  let(:identity_path_valid_value) { "apps/sub-apps" }
  let(:valid_jwt_identity_without_path) {
    ::Authentication::AuthnJwt::IDENTITY_TYPE_HOST +
      ::Authentication::AuthnJwt::PATH_DELIMITER +
      token_identity
  }
  let(:valid_jwt_identity_from_hash) {
    ::Authentication::AuthnJwt::IDENTITY_TYPE_HOST +
      ::Authentication::AuthnJwt::PATH_DELIMITER +
      "n_value"
  }
  let(:valid_jwt_identity_from_array) {
    ::Authentication::AuthnJwt::IDENTITY_TYPE_HOST +
      ::Authentication::AuthnJwt::PATH_DELIMITER +
      "a_value_1"
  }
  let(:valid_jwt_identity_with_path) {
    ::Authentication::AuthnJwt::IDENTITY_TYPE_HOST +
      ::Authentication::AuthnJwt::PATH_DELIMITER +
      identity_path_valid_value +
      ::Authentication::AuthnJwt::PATH_DELIMITER +
      token_identity
  }

  before(:each) do
    allow(jwt_authenticator_input).to(
      receive(:decoded_token).and_return(decoded_token)
    )

    allow(mocked_authenticator_secret_exists).to(
      receive(:call).and_return(true)
    )

    allow(mocked_authenticator_secret_not_exists).to(
      receive(:call).and_return(false)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).and_return(mocked_valid_secrets)
    )

    allow(mocked_fetch_authenticator_secrets_value_points_to_array).to(
      receive(:call).and_return(mocked_valid_secret_value_points_to_array)
    )

    allow(mocked_fetch_authenticator_secrets_value_hash).to(
      receive(:call).and_return(mocked_valid_secret_hash)
    )

    allow(mocked_fetch_authenticator_secrets_value_array).to(
      receive(:call).and_return(mocked_valid_secret_array)
    )

    allow(mocked_fetch_authenticator_secrets_which_missing_in_token).to(
      receive(:call).and_return(mocked_valid_secrets_which_missing_in_token)
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_fetch_identity_path_failed).to(
      receive(:call).and_raise(fetch_identity_path_missing_error)
    )

    allow(mocked_fetch_identity_path_valid_empty_path).to(
      receive(:call).and_return(identity_path_valid_empty_path)
    )

    allow(mocked_fetch_identity_path_valid_value).to(
      receive(:call).and_return(identity_path_valid_value)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Identity from token with invalid configuration" do
    context "And 'token-app-property' resource not exists " do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_not_exists
        )
      end

      it "jwt_identity raise an error" do
        expect {
          subject.call(
            jwt_authenticator_input: jwt_authenticator_input
          )
        }.to raise_error(Errors::Conjur::RequiredResourceMissing)
      end
    end

    context "'token-app-property' resource exists" do
      context "with empty value" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_values
          )
        end

        it "jwt_identity raise an error" do
          expect {
            subject.call(
              jwt_authenticator_input: jwt_authenticator_input
            )
          }.to raise_error(required_secret_missing_error)
        end
      end

      context "With value path contains an array indexes" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_value_array,
            fetch_identity_path: mocked_fetch_identity_path_valid_empty_path
          )
        end

        it "jwt_identity raises an error" do
          expect {
            subject.call(
              jwt_authenticator_input: jwt_authenticator_input
            )
          }.to raise_error(Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyClaimPath)
        end
      end

      context "With value points to array in token" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_value_points_to_array,
            fetch_identity_path: mocked_fetch_identity_path_valid_empty_path
          )
        end

        it "jwt_identity raises an error" do
          expect {
            subject.call(
              jwt_authenticator_input: jwt_authenticator_input
            )
          }.to raise_error(Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsArray)
        end
      end

      context "And 'identity-path' resource exists with empty value" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
            fetch_identity_path: mocked_fetch_identity_path_failed
          )
        end

        it "jwt_identity raise an error" do
          expect {
            subject.call(
              jwt_authenticator_input: jwt_authenticator_input
            )
          }.to raise_error(fetch_identity_path_missing_error)
        end
      end

      context "And identity token claim not exists in decode token " do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_which_missing_in_token
          )
        end

        it "jwt_identity raise an error" do
          expect {
            subject.call(
              jwt_authenticator_input: jwt_authenticator_input
            )
          }.to raise_error(Errors::Authentication::AuthnJwt::NoSuchFieldInToken)
        end
      end
    end
  end

  context "Identity from token configured correctly" do
    context "And 'token-app-property' resource exists with value" do
      context "And 'identity-path' resource not exists (valid configuration, empty path will be returned)" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
            fetch_identity_path: mocked_fetch_identity_path_valid_empty_path
          ).call(
            jwt_authenticator_input: jwt_authenticator_input
          )
        end

        it "jwt_identity returns host identity" do
          expect(subject).to eql(valid_jwt_identity_without_path)
        end
      end

      context "And 'identity-path' resource not exists, token-app-property from nested hash" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_value_hash,
            fetch_identity_path: mocked_fetch_identity_path_valid_empty_path
          ).call(
            jwt_authenticator_input: jwt_authenticator_input
          )
        end

        it "jwt_identity returns host identity" do
          expect(subject).to eql(valid_jwt_identity_from_hash)
        end
      end

      context "And 'identity-path' resource exists with value" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::IdentityFromDecodedTokenProvider.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_exists,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
            fetch_identity_path: mocked_fetch_identity_path_valid_value
          ).call(
            jwt_authenticator_input: jwt_authenticator_input
          )
        end

        it "jwt_identity returns host identity" do
          expect(subject).to eql(valid_jwt_identity_with_path)
        end
      end
    end
  end
end
