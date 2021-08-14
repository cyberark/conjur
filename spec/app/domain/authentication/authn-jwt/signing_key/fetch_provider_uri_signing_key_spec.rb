# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }
  let(:mocked_authentication_parameters) {
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

  let(:required_provider_uri_configuration_error) { "required provider_uri configuration missing error" }
  let(:required_discover_identity_error) { "Provider uri identity error" }
  let(:required_secret_missing_error) { "required secret missing error" }

  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_fetch_authenticator_secrets_exist_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:mocked_discover_identity_provider) { double("Mocked discover identity provider")  }
  let(:mocked_invalid_uri_discover_identity_provider) { double("Mocked invalid uri discover identity provider")  }
  let(:mocked_provider_uri) { double("Mocked provider uri")  }

  let(:mocked_valid_discover_identity_result) { "some jwks" }
  let(:valid_jwks_result) { {:keys=> mocked_valid_discover_identity_result} }

  before(:each) do
    allow(mocked_logger).to(
      receive(:call).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:debug).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:info).and_return(true)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).and_return('provider-uri' => 'https://provider-uri.com/provider')
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_discover_identity_provider).to(
      receive(:call).and_return(mocked_provider_uri)
    )

    allow(mocked_provider_uri).to(
      receive(:jwks).and_return(mocked_valid_discover_identity_result)
    )

    allow(mocked_invalid_uri_discover_identity_provider).to(
      receive(:call).and_raise(required_discover_identity_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchProviderUriSigningKey fetch_signing_key " do
    context "'provider-uri' variable is configured in authenticator policy" do
      context "'provider-uri' value is invalid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                     logger: mocked_logger,
                                                                     fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
                                                                     discover_identity_provider: mocked_invalid_uri_discover_identity_provider).fetch_signing_key
        end

        it "raises an error" do
          expect { subject }.to raise_error(required_discover_identity_error)
        end
      end

      context "'provider-uri' value is valid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                     logger: mocked_logger,
                                                                     fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
                                                                     discover_identity_provider: mocked_discover_identity_provider).fetch_signing_key
        end

        it "does not raise error" do
          expect(subject).to eql(valid_jwks_result)
        end
      end
    end
  end
end
