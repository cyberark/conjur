# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface') do

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
  let(:mocked_fetch_non_exists_jwks_uri) { double("Mocked fetch with non-existing jwks-uri")  }
  let(:mocked_exists_has_valid_configuration) { double("Mocked valid configuration")  }
  let(:mocked_non_exists_has_valid_configuration) { double("Mocked invalid configuration")  }
  let(:mocked_logger) { double("Mocked logger")  }

  before(:each) do
    allow(mocked_fetch_exists_provider_uri).to(
      receive(:new).and_return(mocked_exists_has_valid_configuration)
    )

    allow(mocked_fetch_non_exists_provider_uri).to(
      receive(:new).and_return(mocked_non_exists_has_valid_configuration)
    )

    allow(mocked_fetch_exists_jwks_uri).to(
      receive(:new).and_return(mocked_exists_has_valid_configuration)
    )

    allow(mocked_fetch_non_exists_jwks_uri).to(
      receive(:new).and_return(mocked_non_exists_has_valid_configuration)
    )

    allow(mocked_exists_has_valid_configuration).to(
      receive(:valid_configuration?).and_return(true)
    )

    allow(mocked_non_exists_has_valid_configuration).to(
      receive(:valid_configuration?).and_return(false)
    )

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

  context "CreateSigningKeyInterface " do
    context "'jwks-uri' and 'provider-uri' exist" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new(
          fetch_provider_uri: mocked_fetch_exists_provider_uri,
          fetch_jwks_uri: mocked_fetch_exists_jwks_uri,
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
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new(
          fetch_provider_uri: mocked_fetch_non_exists_provider_uri,
          fetch_jwks_uri: mocked_fetch_non_exists_jwks_uri,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidUriConfiguration)
      end
    end

    context "'jwks-uri' does not exits and 'provider-uri' exists" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new(
          fetch_provider_uri: mocked_fetch_non_exists_provider_uri,
          fetch_jwks_uri: mocked_fetch_exists_jwks_uri,
          logger: mocked_logger
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "'jwks-uri' exists and 'provider-uri' does not exist" do

      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new(
          fetch_provider_uri: mocked_fetch_exists_provider_uri,
          fetch_jwks_uri: mocked_fetch_non_exists_jwks_uri,
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
