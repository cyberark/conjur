# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviders::IdentityProviderFactory') do
  # Mock to inject to test in order check returning type
  class MockedURLIdentityProvider
    def initialize(authentication_parameters); end
  end

  # Mock to inject to test in order check returning type
  class MockedDecodedTokenIdentityProvider
    def initialize(authentication_parameters); end
  end

  # Mock to CheckAuthenticatorSecretExists that returns always false
  class MockedCheckAuthenticatorSecretExistsFalse
    # this what the object gets and its a mock
    # :reek:LongParameterList :reek:UnusedParameters - this what the object gets and its a mock
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      false
    end
  end

  # Mock to CheckAuthenticatorSecretExists that returns always true
  class MockedCheckAuthenticatorSecretExistsTrue
    # this what the object gets and its a mock
    # :reek:LongParameterList and :reek:UnusedParameters
    def call(conjur_account:, authenticator_name:, service_id:, var_name:)
      true
    end
  end

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authentication_parameters_url_identity) {
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

  let(:authentication_parameters_no_url_identity) {
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: nil,
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      jwt_token: nil
    )
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "IdentityProviderFactory" do
    context "Decoded token identity available and url identity available" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new(
          identity_from_url_provider_class: MockedURLIdentityProvider,
          identity_from_decoded_token_class: MockedDecodedTokenIdentityProvider,
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsTrue.new
        )
      end

      it "factory raises IdentityMisconfigured" do
        expect { subject.call(
          authentication_parameters: authentication_parameters_url_identity
        ) }.to raise_error(Errors::Authentication::AuthnJwt::IdentityMisconfigured)
      end
    end

    context "Decoded token identity available and url identity is not available" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new(
          identity_from_url_provider_class: MockedURLIdentityProvider,
          identity_from_decoded_token_class: MockedDecodedTokenIdentityProvider,
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsTrue.new
        )
      end

      it "factory to return IdentityFromDecodedTokenProvider" do
        expect(subject.call(
          authentication_parameters: authentication_parameters_no_url_identity
        )).to be_a(MockedDecodedTokenIdentityProvider)
      end
    end

    context "Decoded token identity is not available and url identity is available" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new(
          identity_from_url_provider_class: MockedURLIdentityProvider,
          identity_from_decoded_token_class: MockedDecodedTokenIdentityProvider,
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsFalse.new
        )
      end

      it "factory to return IdentityFromUrlProvider" do
        expect(subject.call(
          authentication_parameters: authentication_parameters_url_identity
        )).to be_a(MockedURLIdentityProvider)
      end
    end

    context "Decoded token is not identity available and url identity is not available" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new(
          check_authenticator_secret_exists: MockedCheckAuthenticatorSecretExistsFalse.new
        )
      end

      it "factory raises NoRelevantIdentityProvider" do
        expect { subject.call(
          authentication_parameters: authentication_parameters_no_url_identity
        ) }.to raise_error(Errors::Authentication::AuthnJwt::IdentityMisconfigured)
      end
    end
  end
end
