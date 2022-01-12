
require 'spec_helper'
RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables') do

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
  let(:mocked_provider_type) { Authentication::AuthnJwt::PROVIDER_URI_INTERFACE_NAME }
  let(:mocked_provider_uri) { 'https://provider-uri.com/provider' }
  let(:mocked_jwks_type) { Authentication::AuthnJwt::JWKS_URI_INTERFACE_NAME }
  let(:mocked_jwks_uri) { 'http://jwks-uri.com/jwks' }

  let(:mocked_check_authenticator_secret_exists_nothing_exists) { double("mockedCheckAuthenticatorSecretExistsNothingExists") }
  let(:mocked_check_authenticator_secret_exists_everything_exists) { double("mockedCheckAuthenticatorSecretExistsEverythingExists") }
  let(:mocked_check_authenticator_secret_exists_jwks)  {  double("mockedCheckAuthenticatorSecretExistsJwks") }
  let(:mocked_check_authenticator_secret_exists_provider)  {  double("mockedCheckAuthenticatorSecretExistsProvider") }
  let(:mocked_fetch_authenticator_secrets_exist_jwks) { double("mockedFetchAuthenticatorSecretsExistJwks") }
  let(:mocked_fetch_authenticator_secrets_not_exist_jwks) { double("mockedFetchAuthenticatorSecretsExistJwks")}
  let(:mocked_fetch_authenticator_secrets_empty_provider) { double("mockedFetchAuthenticatorSecretsEmptyProvider")}
  let(:mocked_fetch_authenticator_secrets_exist_provider)  {  double("MockedFetchAuthenticatorSecretsExistProvider") }
  let(:mocked_logger) { double("mockedLogger")  }
  let(:mocked_required_secret_missing_error) { "mockedRequiredSecretMissingError" }

  before(:each) do
    allow(mocked_check_authenticator_secret_exists_nothing_exists).to(
      receive(:call).and_return(false)
    )

    allow(mocked_check_authenticator_secret_exists_everything_exists).to(
      receive(:call).and_return(true)
    )

    allow(mocked_check_authenticator_secret_exists_jwks).to(
      receive(:call).with(
        conjur_account: anything,
        authenticator_name: anything,
        service_id: anything,
        var_name: "jwks-uri"
      ).and_return(true)
    )

    allow(mocked_check_authenticator_secret_exists_jwks).to(
      receive(:call).with(
        conjur_account: anything,
        authenticator_name: anything,
        service_id: anything,
        var_name: "provider-uri"
      ).and_return(false)
    )

    allow(mocked_check_authenticator_secret_exists_provider).to(
      receive(:call).with(
        conjur_account: anything,
        authenticator_name: anything,
        service_id: anything,
        var_name: "jwks-uri"
      ).and_return(false)
    )

    allow(mocked_check_authenticator_secret_exists_provider).to(
      receive(:call).with(
        conjur_account: anything,
        authenticator_name: anything,
        service_id: anything,
        var_name: "provider-uri"
      ).and_return(true)
    )

    allow(mocked_fetch_authenticator_secrets_exist_jwks).to(
      receive(:call).and_return('jwks-uri' => mocked_jwks_uri)
    )

    allow(mocked_fetch_authenticator_secrets_not_exist_jwks).to(
      receive(:call).and_raise(mocked_required_secret_missing_error)
    )

    allow(mocked_fetch_authenticator_secrets_exist_provider).to(
      receive(:call).and_return('provider-uri' => mocked_provider_uri)
    )

    allow(mocked_fetch_authenticator_secrets_empty_provider).to(
      receive(:call).and_raise(mocked_required_secret_missing_error)
    )

    allow(mocked_logger).to(
      receive(:call).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:debug).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:info).and_return(true)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "fetchiSigningKeySettingsFromVariables " do
    context "'jwks-uri' and 'provider-uri' exist" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
          check_authenticator_secret_exists: mocked_check_authenticator_secret_exists_everything_exists
        ).call(
          authenticator_input: mocked_authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::InvalidUriConfiguration,
                                "CONJ00086E Signing key URI configuration is invalid")
      end
    end

    context "'jwks-uri' and 'provider-uri' do not exist" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
          check_authenticator_secret_exists: mocked_check_authenticator_secret_exists_nothing_exists
        ).call(
          authenticator_input: mocked_authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::InvalidUriConfiguration,
                                "CONJ00086E Signing key URI configuration is invalid")
      end
    end

    context "'jwks-uri' exits and 'provider-uri' do not exist" do
      context "fetching 'jwks-uri' successfully" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
            check_authenticator_secret_exists:  mocked_check_authenticator_secret_exists_jwks,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_jwks,
            logger: mocked_logger
          ).call(
            authenticator_input: mocked_authenticator_input
          )
        end

        it "equals to expected signing key settings" do
          expect(subject.uri).to eql(mocked_jwks_uri)
          expect(subject.type).to eql(mocked_jwks_type)
        end
      end

      context "fetching 'jwks-uri' not successfully" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
            check_authenticator_secret_exists:  mocked_check_authenticator_secret_exists_jwks,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_not_exist_jwks,
            logger: mocked_logger
          ).call(
            authenticator_input: mocked_authenticator_input
          )
        end

        it "raise an error" do
          expect { subject }.to raise_error(mocked_required_secret_missing_error)
        end
      end
    end

    context "'jwks-uri' does not exist and 'provider-uri' exists" do
      context "fetching 'provider-uri' successfully" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
            check_authenticator_secret_exists:  mocked_check_authenticator_secret_exists_provider,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_provider,
            logger: mocked_logger,
            ).call(
            authenticator_input: mocked_authenticator_input
          )
        end

        it "equals to expected signing key settings" do
          expect(subject.uri).to eql(mocked_provider_uri)
          expect(subject.type).to eql(mocked_provider_type)
        end
      end

      context "fetching 'provider-uri' not successfully" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchSigningKeySettingsFromVariables.new(
            check_authenticator_secret_exists:  mocked_check_authenticator_secret_exists_provider,
            fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_provider,
            logger: mocked_logger
          ).call(
            authenticator_input: mocked_authenticator_input
          )
        end

        it "raise an error" do
          expect { subject }.to raise_error(mocked_required_secret_missing_error)
        end
      end
    end
  end
end
