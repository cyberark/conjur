# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdFromUrlProvider') do
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
      jwt_token: nil)
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "IdFromUrlProvider" do
    context "There is identity in the url" do
      subject do
        ::Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_url_identity)
      end

      it "id_available? return true" do
        expect(subject.identity_available?).to eql(true)
      end

      it "provide_jwt_id to provide identity from url successfully" do
        expect(subject.provide_jwt_identity).to eql("dummy_identity")
      end
    end

    context "There is no identity in the url" do
      subject do
        ::Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters_no_url_identity)
      end

      it "id_available? return false" do
        expect(subject.identity_available?).to eql(false)
      end

      it "provide_jwt_id to raise NoUsernameInTheURL" do
        expect { subject.provide_jwt_identity }.to raise_error(Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider)
      end
    end
  end
end
