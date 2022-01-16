
require 'spec_helper'
RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchSigningKeyParametersFromVariables') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }
  let(:mocked_authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    )
  }

  let(:jwks_uri_key) { "jwks-uri" }
  let(:jwks_uri_value) { "https://jwks-uri.com/jwks" }
  let(:jwks_key_value_pair) {
    {
      jwks_uri_key => jwks_uri_value
    }
  }

  let(:provider_uri_key) { "provider-uri" }
  let(:provider_uri_value) { "https://provider-uri.com" }
  let(:provider_key_value_pair) {
    {
      provider_uri_key => provider_uri_value
    }
  }

  let(:jwks_only_hash) {
    {
      "ca-cert" => nil,
      "issuer" => nil,
      "jwks-uri" => "https://jwks-uri.com/jwks",
      "provider-uri" => nil,
      "public-keys" => nil
    }
  }

  let(:jwks_and_provider_hash) {
    {
      "ca-cert" => nil,
      "issuer" => nil,
      "jwks-uri" => "https://jwks-uri.com/jwks",
      "provider-uri" => "https://provider-uri.com",
      "public-keys" => nil
    }
  }

  let(:mocked_check_authenticator_secret_exists_valid_settings) { double("mocked_check_authenticator_secret_exists_valid_settings") }
  let(:mocked_fetch_authenticator_secrets_valid_settings) { double("mocked_fetch_authenticator_secrets_valid_settings") }

  let(:mocked_check_authenticator_secret_exists_invalid_settings) { double("mocked_check_authenticator_secret_exists_invalid_settings") }
  let(:mocked_fetch_authenticator_secrets_invalid_settings) { double("mocked_fetch_authenticator_secrets_invalid_settings") }

  let(:mocked_fetch_authenticator_secrets_empty_value) { double("mocked_fetch_authenticator_secrets_empty_value") }
  let(:empty_value_error) { "empty value error" }

  before(:each) do
    allow(mocked_check_authenticator_secret_exists_valid_settings).to(
      receive(:call).and_return(false)
    )

    allow(mocked_check_authenticator_secret_exists_valid_settings).to(
      receive(:call).with(
        conjur_account: account,
        authenticator_name: authenticator_name,
        service_id: service_id,
        var_name: jwks_uri_key
      ).and_return(true)
    )

    allow(mocked_fetch_authenticator_secrets_valid_settings).to(
      receive(:call).and_return(jwks_key_value_pair)
    )

    allow(mocked_check_authenticator_secret_exists_invalid_settings).to(
      receive(:call).and_return(false)
    )

    allow(mocked_check_authenticator_secret_exists_invalid_settings).to(
      receive(:call).with(
        conjur_account: account,
        authenticator_name: authenticator_name,
        service_id: service_id,
        var_name: jwks_uri_key
      ).and_return(true)
    )

    allow(mocked_check_authenticator_secret_exists_invalid_settings).to(
      receive(:call).with(
        conjur_account: account,
        authenticator_name: authenticator_name,
        service_id: service_id,
        var_name: provider_uri_key
      ).and_return(true)
    )

    allow(mocked_fetch_authenticator_secrets_invalid_settings).to(
      receive(:call).with(
        conjur_account: account,
        authenticator_name: authenticator_name,
        service_id: service_id,
        required_variable_names: [jwks_uri_key]
      ).and_return(jwks_key_value_pair)
    )

    allow(mocked_fetch_authenticator_secrets_invalid_settings).to(
      receive(:call).with(
        conjur_account: account,
        authenticator_name: authenticator_name,
        service_id: service_id,
        required_variable_names: [provider_uri_key]
      ).and_return(provider_key_value_pair)
    )

    allow(mocked_fetch_authenticator_secrets_empty_value).to(
      receive(:call).and_raise(empty_value_error)
    )
  end


  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchSigningKeyParametersFromVariables call" do
    context "with jwks-uri variable only" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchSigningKeyParametersFromVariables.new(
          check_authenticator_secret_exists: mocked_check_authenticator_secret_exists_valid_settings,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_valid_settings
        ).call(
          authenticator_input: mocked_authenticator_input
        )
      end

      it "returns signing key settings hash" do
        expect(subject).to eq(jwks_only_hash)
      end
    end

    context "with jwks and provider URIs variables" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchSigningKeyParametersFromVariables.new(
          check_authenticator_secret_exists: mocked_check_authenticator_secret_exists_invalid_settings,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_invalid_settings
        ).call(
          authenticator_input: mocked_authenticator_input
        )
      end

      it "returns signing key settings hash" do
        expect(subject).to eq(jwks_and_provider_hash)
      end
    end

    context "when one of variable values is empty" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchSigningKeyParametersFromVariables.new(
          check_authenticator_secret_exists: mocked_check_authenticator_secret_exists_invalid_settings,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_value
        ).call(
          authenticator_input: mocked_authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(empty_value_error)
      end
    end
  end
end
