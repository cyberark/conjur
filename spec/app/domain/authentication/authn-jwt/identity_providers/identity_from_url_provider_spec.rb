# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdFromUrlProvider') do
  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:mocked_jwt_authenticator_input_with_url_identity) {
    Authentication::AuthnJwt::JWTAuthenticatorInput.new(
      authenticator_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: "dummy_identity",
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      decoded_token: nil
    )
  }

  let(:mocked_jwt_authenticator_input_without_url_identity) {
    Authentication::AuthnJwt::JWTAuthenticatorInput.new(
      authenticator_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: nil,
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      decoded_token: nil
    )
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "IdFromUrlProvider" do
    context "There is identity in the url" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::IdentityFromUrlProvider.new.call(
          jwt_authenticator_input: mocked_jwt_authenticator_input_with_url_identity
        )
      end

      it "provide_jwt_id to provide identity from url successfully" do
        expect(subject).to eql("dummy_identity")
      end
    end

    context "There is no identity in the url" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::IdentityFromUrlProvider.new
      end

      it "provide_jwt_id to raise NoUsernameInTheURL" do
        expect {
          subject.call(
            jwt_authenticator_input: mocked_jwt_authenticator_input_without_url_identity
          )
        }.to raise_error(Errors::Authentication::AuthnJwt::IdentityMisconfigured)
      end
    end
  end
end
