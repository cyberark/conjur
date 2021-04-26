# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::FetchIssuerValue') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    )
  }

  let(:issuer_resource_name) {'issuer'}
  let(:provider_uri_resource_name) {'provider-uri'}
  let(:jwks_uri_resource_name) {'jwks-uri'}
  let(:issuer_secret_value) {'issuer-secret-value'}
  let(:provider_uri_secret_value) {'provider-uri-secret-value'}
  let(:jwks_uri_secret_value) {'jwks-uri-secret-value'}
  let(:jwks_uri_with_bad_uri_format_value) {'=>=>=>////'}
  let(:jwks_uri_with_bad_uri_hostname_value) {'https://'}
  let(:jwks_uri_with_valid_hostname_value) {'https://jwt-provider.com/jwks'}
  let(:valid_hostname_value) {'jwt-provider.com'}

  def mock_resource_id(resource_name:)
    %r{#{account}:variable:conjur/#{authenticator_name}/#{service_id}/#{resource_name}}
  end

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_resource_exists_values) { double("MockedResource") }
  let(:mocked_resource_not_exists_values) { double("MockedResource") }
  let(:mocked_resource_both_provider_and_jwks_exist_values) { double("MockedResource") }
  let(:mocked_resource_just_provider_uri_exists_values) { double("MockedResource") }
  let(:mocked_resource_just_jwks_uri_exists_values) { double("MockedResource") }

  let(:mocked_fetch_secrets_empty_values) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_exist_values) {  double("MockedFetchSecrets") }
  let(:mocked_valid_secrets) {  double("MockedValidSecrets") }
  let(:mocked_fetch_secrets_jwks_uri_with_bad_uri_format_value) {  double("MockedInvalidSecrets") }
  let(:mocked_fetch_secrets_jwks_uri_with_bad_uri_hostname_value) {  double("MockedInvalidSecrets") }
  let(:mocked_fetch_secrets_jwks_uri_with_valid_uri_hostname_value) {  double("MockedValidSecrets") }
  let(:mocked_jwks_uri_with_bad_uri_format_secret) {  double("MockedInvalidSecrets") }
  let(:mocked_jwks_uri_with_bad_uri_hostname_secret) {  double("MockedInvalidSecrets") }
  let(:mocked_jwks_uri_with_valid_uri_hostname_secret) {  double("MockedValidSecrets") }

  let(:required_secret_missing_error) { "required secret missing error" }
  let(:invalid_issuer_configuration_error) { "invalid issuer configuration error" }

  before(:each) do
    allow(mocked_resource_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: issuer_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_not_exists_values).to(
      receive(:[]).and_return(nil)
    )

    allow(mocked_resource_both_provider_and_jwks_exist_values).to(
      receive(:[]).with(mock_resource_id(resource_name: issuer_resource_name)).and_return(nil)
    )

    allow(mocked_resource_both_provider_and_jwks_exist_values).to(
      receive(:[]).with(mock_resource_id(resource_name: provider_uri_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_both_provider_and_jwks_exist_values).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_just_provider_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: issuer_resource_name)).and_return(nil)
    )

    allow(mocked_resource_just_provider_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: provider_uri_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_just_provider_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).and_return(nil)
    )

    allow(mocked_resource_just_jwks_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: issuer_resource_name)).and_return(nil)
    )

    allow(mocked_resource_just_jwks_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: provider_uri_resource_name)).and_return(nil)
    )

    allow(mocked_resource_just_jwks_uri_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_fetch_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_fetch_secrets_exist_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: issuer_resource_name)]).
        and_return(mocked_valid_secrets)
    )

    allow(mocked_valid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: issuer_resource_name)).
        and_return(issuer_secret_value)
    )

    allow(mocked_fetch_secrets_exist_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: provider_uri_resource_name)]).
        and_return(mocked_valid_secrets)
    )

    allow(mocked_valid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: provider_uri_resource_name)).
        and_return(provider_uri_secret_value)
    )

    allow(mocked_fetch_secrets_exist_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: jwks_uri_resource_name)]).
        and_return(jwks_uri_resource_name)
    )

    allow(mocked_valid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).
        and_return(jwks_uri_secret_value)
    )

    allow(mocked_fetch_secrets_jwks_uri_with_bad_uri_format_value).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: jwks_uri_resource_name)]).
        and_return(mocked_jwks_uri_with_bad_uri_format_secret)
    )

    allow(mocked_jwks_uri_with_bad_uri_format_secret).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).
        and_return(jwks_uri_with_bad_uri_format_value)
    )

    allow(mocked_fetch_secrets_jwks_uri_with_bad_uri_hostname_value).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: jwks_uri_resource_name)]).
        and_return(mocked_jwks_uri_with_bad_uri_hostname_secret)
    )

    allow(mocked_jwks_uri_with_bad_uri_hostname_secret).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).
        and_return(jwks_uri_with_bad_uri_hostname_value)
    )

    allow(mocked_fetch_secrets_jwks_uri_with_valid_uri_hostname_value).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: jwks_uri_resource_name)]).
        and_return(mocked_jwks_uri_with_valid_uri_hostname_secret)
    )

    allow(mocked_jwks_uri_with_valid_uri_hostname_secret).to(
      receive(:[]).with(mock_resource_id(resource_name: jwks_uri_resource_name)).
        and_return(jwks_uri_with_valid_hostname_value)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'issuer' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::FetchIssuerValue.new(
          resource_class: mocked_resource_exists_values,
          fetch_secrets: mocked_fetch_secrets_empty_values
        ).call(
          authenticator_input: authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_secret_missing_error)
      end
    end

    context "with valid variable value" do
      subject do
        ::Authentication::AuthnJwt::FetchIssuerValue.new(
          resource_class: mocked_resource_exists_values,
          fetch_secrets: mocked_fetch_secrets_exist_values
        ).call(
          authenticator_input: authenticator_input
        )
      end

      it "returns issuer value" do
        expect(subject).to eql(issuer_secret_value)
      end
    end
  end

  context "'issuer' variable is not configured in authenticator policy" do
    context "And both provider-uri and jwks-uri not configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchIssuerValue.new(
          resource_class: mocked_resource_not_exists_values,
        ).call(
          authenticator_input: authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidIssuerConfiguration)
      end
    end

    context "And both provider-uri and jwks-uri configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchIssuerValue.new(
          resource_class: mocked_resource_both_provider_and_jwks_exist_values,
          ).call(
          authenticator_input: authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidIssuerConfiguration)
      end
    end

    context "And just provider-uri configured in authenticator policy" do
      context "with empty variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_provider_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_empty_values
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(required_secret_missing_error)
        end 
      end

      context "with valid variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_provider_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_exist_values
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "returns provider-uri as issuer value" do
          expect(subject).to eql(provider_uri_secret_value)
        end
      end
    end

    context "And just jwks-uri configured in authenticator policy" do
      context "with empty variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_jwks_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_empty_values
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(required_secret_missing_error)
        end
      end

      context "with bad URI format as variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_jwks_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_jwks_uri_with_bad_uri_format_value
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidUriFormat)
        end
      end

      context "with bad URI hostname as variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_jwks_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_jwks_uri_with_bad_uri_hostname_value
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToParseHostnameFromUri)
        end
      end

      context "with valid URI hostname as variable value" do
        subject do
          ::Authentication::AuthnJwt::FetchIssuerValue.new(
            resource_class: mocked_resource_just_jwks_uri_exists_values,
            fetch_secrets: mocked_fetch_secrets_jwks_uri_with_valid_uri_hostname_value
          ).call(
            authenticator_input: authenticator_input
          )
        end

        it "returns extracted hostname from jwks-uri as issuer value" do
          expect(subject).to eql(valid_hostname_value)
        end
      end
    end
  end
end

