# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider') do
  class MockedCheckAuthenticatorSecretExistsJWKS
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      var_name == "jwks-uri"
    end
  end

  class MockedCheckAuthenticatorSecretExistsProviderUri
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      var_name == "provider-uri"
    end
  end

  class MockedCheckAuthenticatorSecretExistsFalse
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      false
    end
  end

  class MockedCheckAuthenticatorSecretExistsTrue
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      true
    end
  end

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: "dummy_identity",
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      jwt_token: nil
    )
  }

  let(:mocked_fetch_exists_provider_uri) { double("Mocked fetch with existing provider-uri")  }
  let(:mocked_fetch_non_exists_provider_uri) { double("Mocked fetch with non-existing provider-uri")  }
  let(:mocked_fetch_exists_jwks_uri) { double("Mocked fetch with existing jwks-uri")  }
  let(:mocked_check_authenticator_secret_exists_jwks) { double("CheckAuthenticatorSecretExists") }
  let(:mocked_check_authenticator_secret_exists_provider_uri) { double("CheckAuthenticatorSecretExists") }
  let(:mocked_check_authenticator_secret_exits_jwks_and_provider_uri) { double("CheckAuthenticatorSecretNotExists") }
  let(:mocked_check_authenticator_secret_not_exists) { double("CheckAuthenticatorSecretNotExists") }
  let(:mocked_logger) { double("Mocked logger")  }

  before(:each) do
    allow(mocked_logger).to(
      receive(:debug).and_return(nil)
    )

    allow(mocked_logger).to(
      receive(:info).and_return(nil)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "CreateSigningKeyProvider " do
    context "'jwks-uri' and 'provider-uri' exist" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new(
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsTrue.new,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidUriConfiguration)
      end
    end

    context "'jwks-uri' and 'provider-uri' does not exist" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new(
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsFalse.new,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidUriConfiguration)
      end
    end

    context "'jwks-uri' exits and 'provider-uri' does not exists" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new(
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsJWKS.new,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "'jwks-uri' does not exists and 'provider-uri' exist" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new(
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsProviderUri.new,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

  end
end
