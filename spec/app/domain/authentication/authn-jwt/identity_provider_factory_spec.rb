# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviderFactory') do
  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authentication_parameters_url_identity) {
    Authentication::AuthnJwt::AuthenticationParameters.new(Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    ))
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "IdentityProviderFactory" do
    context "Decoded token identity available and url identity available" do
      subject do
        authentication_provider_factory = ::Authentication::AuthnJwt::IdentityProviderFactory.new(authentication_parameters_url_identity)
        from_decoded_token_provider = Authentication::AuthnJwt::IdentityFromDecodedTokenProvider.new(authentication_parameters_url_identity)
        from_url_provider = Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_url_identity)
        allow(from_decoded_token_provider).to receive(:identity_available?).and_return(true)
        allow(from_url_provider).to receive(:identity_available?).and_return(true)
        authentication_provider_factory.from_decoded_token_provider = from_decoded_token_provider
        authentication_provider_factory.from_url_provider = from_url_provider
        authentication_provider_factory
      end

      it "factory to return IdentityFromDecodedTokenProvider" do
        expect(subject.relevant_id_provider).to be_a(Authentication::AuthnJwt::IdentityFromDecodedTokenProvider)
      end
    end

    context "Decoded token identity available and url identity is not available" do
      subject do
        authentication_provider_factory = ::Authentication::AuthnJwt::IdentityProviderFactory.new(authentication_parameters_url_identity)
        from_decoded_token_provider = Authentication::AuthnJwt::IdentityFromDecodedTokenProvider.new(authentication_parameters_url_identity)
        from_url_provider = Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_url_identity)
        allow(from_decoded_token_provider).to receive(:identity_available?).and_return(true)
        allow(from_url_provider).to receive(:identity_available?).and_return(false)
        authentication_provider_factory.from_decoded_token_provider = from_decoded_token_provider
        authentication_provider_factory.from_url_provider = from_url_provider
        authentication_provider_factory
      end

      it "factory to return IdentityFromDecodedTokenProvider" do
        expect(subject.relevant_id_provider).to be_a(Authentication::AuthnJwt::IdentityFromDecodedTokenProvider)
      end
    end

    context "Decoded token is not identity available and url identity is available" do
      subject do
        authentication_provider_factory = ::Authentication::AuthnJwt::IdentityProviderFactory.new(authentication_parameters_url_identity)
        from_decoded_token_provider = Authentication::AuthnJwt::IdentityFromDecodedTokenProvider.new(authentication_parameters_url_identity)
        from_url_provider = Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_url_identity)
        allow(from_decoded_token_provider).to receive(:identity_available?).and_return(false)
        allow(from_url_provider).to receive(:identity_available?).and_return(true)
        authentication_provider_factory.from_decoded_token_provider = from_decoded_token_provider
        authentication_provider_factory.from_url_provider = from_url_provider
        authentication_provider_factory
      end

      it "factory to return IdentityFromUrlProvider" do
        expect(subject.relevant_id_provider).to be_a(Authentication::AuthnJwt::IdentityFromUrlProvider)
      end
    end

    context "Decoded token is not identity available and url identity is not available" do
      subject do
        authentication_provider_factory = ::Authentication::AuthnJwt::IdentityProviderFactory.new(authentication_parameters_url_identity)
        from_decoded_token_provider = Authentication::AuthnJwt::IdentityFromDecodedTokenProvider.new(authentication_parameters_url_identity)
        from_url_provider = Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_url_identity)
        allow(from_decoded_token_provider).to receive(:identity_available?).and_return(false)
        allow(from_url_provider).to receive(:identity_available?).and_return(false)
        authentication_provider_factory.from_decoded_token_provider = from_decoded_token_provider
        authentication_provider_factory.from_url_provider = from_url_provider
        authentication_provider_factory
      end

      it "factory raises NoRelevantIdentityProvider" do
        expect { subject.relevant_id_provider }.to raise_error(Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider)
      end
    end
  end
end
