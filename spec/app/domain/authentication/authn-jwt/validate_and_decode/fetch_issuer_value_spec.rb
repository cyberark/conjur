# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue') do

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

  let(:check_authenticator_secret_exists_issuer_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :var_name => issuer_resource_name
    }
  }

  let(:check_authenticator_secret_exists_jwks_uri_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :var_name => jwks_uri_resource_name
    }
  }

  let(:check_authenticator_secret_exists_provider_uri_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :var_name => provider_uri_resource_name
    }
  }


  let(:mocked_authenticator_secret_issuer_exist) { double("MockedCheckAuthenticatorSecretExists") }
  let(:mocked_authenticator_secret_nothing_exist) { double("MockedCheckAuthenticatorSecretExists") }
  let(:mocked_authenticator_secret_both_jwks_and_provider_uri) { double("MockedCheckAuthenticatorSecretExists") }
  let(:mocked_authenticator_secret_just_jwks_uri) { double("MockedCheckAuthenticatorSecretExists") }
  let(:mocked_authenticator_secret_just_provider_uri) { double("MockedCheckAuthenticatorSecretExists") }

  let(:fetch_authenticator_secret_issuer_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :required_variable_names => [issuer_resource_name]
    }
  }

  let(:fetch_authenticator_secret_jwks_uri_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :required_variable_names => [jwks_uri_resource_name]
    }
  }

  let(:fetch_authenticator_secret_provider_uri_input) {
    {
      :authenticator_name => authenticator_name,
      :conjur_account => account,
      :service_id => service_id,
      :required_variable_names => [provider_uri_resource_name]
    }
  }

  let(:mocked_fetch_authenticator_secret_empty_values) { double("FetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_exist_values) { double("FetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_format_value) {  double("FetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_hostname_value) {  double("FetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_jwks_uri_with_valid_uri_hostname_value) {  double("FetchAuthenticatorSecrets") }

  let(:required_secret_missing_error) { "required secret missing error" }
  let(:invalid_issuer_configuration_error) { "invalid issuer configuration error" }

  before(:each) do
    allow(mocked_authenticator_secret_issuer_exist).to(
      receive(:call).with(check_authenticator_secret_exists_issuer_input).and_return(true)
    )

    allow(mocked_authenticator_secret_nothing_exist).to(
      receive(:call).and_return(false)
    )

    allow(mocked_authenticator_secret_both_jwks_and_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_issuer_input).and_return(false)
    )

    allow(mocked_authenticator_secret_both_jwks_and_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_jwks_uri_input).and_return(true)
    )

    allow(mocked_authenticator_secret_both_jwks_and_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_provider_uri_input).and_return(true)
    )

    allow(mocked_authenticator_secret_just_jwks_uri).to(
      receive(:call).with(check_authenticator_secret_exists_issuer_input).and_return(false)
    )

    allow(mocked_authenticator_secret_just_jwks_uri).to(
      receive(:call).with(check_authenticator_secret_exists_jwks_uri_input).and_return(true)
    )

    allow(mocked_authenticator_secret_just_jwks_uri).to(
      receive(:call).with(check_authenticator_secret_exists_provider_uri_input).and_return(false)
    )

    allow(mocked_authenticator_secret_just_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_issuer_input).and_return(false)
    )

    allow(mocked_authenticator_secret_just_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_jwks_uri_input).and_return(false)
    )

    allow(mocked_authenticator_secret_just_provider_uri).to(
      receive(:call).with(check_authenticator_secret_exists_provider_uri_input).and_return(true)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).with(fetch_authenticator_secret_issuer_input).and_return(issuer_resource_name => issuer_secret_value)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).with(fetch_authenticator_secret_jwks_uri_input).and_return(jwks_uri_resource_name => jwks_uri_secret_value)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).with(fetch_authenticator_secret_provider_uri_input).and_return(provider_uri_resource_name => provider_uri_secret_value)
    )

    allow(mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_format_value).to(
      receive(:call).with(fetch_authenticator_secret_jwks_uri_input).and_return(jwks_uri_resource_name => jwks_uri_with_bad_uri_format_value)
    )

    allow(mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_hostname_value).to(
      receive(:call).with(fetch_authenticator_secret_jwks_uri_input).and_return(jwks_uri_resource_name => jwks_uri_with_bad_uri_hostname_value)
    )

    allow(mocked_fetch_authenticator_secrets_jwks_uri_with_valid_uri_hostname_value).to(
      receive(:call).with(fetch_authenticator_secret_jwks_uri_input).and_return(jwks_uri_resource_name => jwks_uri_with_valid_hostname_value)
    )

    allow(mocked_fetch_authenticator_secret_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'issuer' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_issuer_exist,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secret_empty_values
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
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_issuer_exist,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values
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
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_nothing_exist,
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
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_both_jwks_and_provider_uri,
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_provider_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secret_empty_values
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_provider_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_jwks_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secret_empty_values
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_jwks_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_format_value
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_jwks_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_jwks_uri_with_bad_uri_hostname_value
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
          ::Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new(
            check_authenticator_secret_exists: mocked_authenticator_secret_just_jwks_uri,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_jwks_uri_with_valid_uri_hostname_value
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
