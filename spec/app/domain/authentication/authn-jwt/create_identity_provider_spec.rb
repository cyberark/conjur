# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviderFactory') do
  class FalseIdentityProvider
    def initialize(authentication_parameters); end

    def identity_available?
      false
    end
  end

  class MockedURLIdentityProvider
    def initialize(authentication_parameters); end
    def identity_available?
      true
    end
  end

  class MockedDecodedTokenIdentityProvider
    def initialize(authentication_parameters); end
    def identity_available?
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

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "IdentityProviderFactory" do
    context "Decoded token identity available and url identity available" do
      subject do
        ::Authentication::AuthnJwt::CreateIdentityProvider.new(
          identity_from_url_provider_class: MockedURLIdentityProvider,
          identity_from_decoded_token_class: MockedDecodedTokenIdentityProvider
        )
      end

      it "factory to return IdentityFromDecodedTokenProvider" do
        expect(subject.call(
          authentication_parameters: authentication_parameters_url_identity
        )).to be_a(MockedDecodedTokenIdentityProvider)
      end
    end

    context "Decoded token identity available and url identity is not available" do
      subject do
        ::Authentication::AuthnJwt::CreateIdentityProvider.new(
          identity_from_url_provider_class: FalseIdentityProvider,
          identity_from_decoded_token_class: MockedDecodedTokenIdentityProvider
        )
      end

      it "factory to return IdentityFromDecodedTokenProvider" do
        expect(subject.call(
          authentication_parameters: authentication_parameters_url_identity
        )).to be_a(MockedDecodedTokenIdentityProvider)
      end
    end

    context "Decoded token identity is not available and url identity is available" do
      subject do
        ::Authentication::AuthnJwt::CreateIdentityProvider.new(
          identity_from_url_provider_class: MockedURLIdentityProvider,
          identity_from_decoded_token_class: FalseIdentityProvider
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
        ::Authentication::AuthnJwt::CreateIdentityProvider.new(
          identity_from_url_provider_class: FalseIdentityProvider,
          identity_from_decoded_token_class: FalseIdentityProvider
        )
      end

      it "factory raises NoRelevantIdentityProvider" do
        expect { subject.call(
          authentication_parameters: authentication_parameters_url_identity
        ) }.to raise_error(Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider)
      end
    end
  end
end
