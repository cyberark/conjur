# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Authentication::Oidc' do

  include_context "oidc setup"

  let (:mocked_oidc_authenticator) { double("MockOidcAuthenticator") }

  ####################################
  # oidc id token values
  ####################################

  let(:username) { "my-user" }

  let (:user_info) do
    double('UserInfo').tap do |user_info|
      allow(user_info).to receive(:preferred_username).and_return(username)
    end
  end

  let (:oidc_id_token_details) do
    double('OidcIDTokenDetails').tap do |oidc_id_token_details|
      allow(oidc_id_token_details).to receive(:user_info).and_return(user_info)
      allow(oidc_id_token_details).to receive(:id_token).and_return("id_token")
      allow(oidc_id_token_details).to receive(:expiration_time).and_return("expiration_time")

    end
  end

  ####################################
  # oidc client mock
  ####################################

  let (:oidc_client) do
    double('OidcClient').tap do |client|
      allow(client).to receive(:oidc_id_token_details).and_return(oidc_id_token_details)
    end
  end

  let (:oidc_client_class) do
    double('OidcClientClass').tap do |client_class|
      allow(client_class).to receive(:new).and_return(oidc_client)
    end
  end

  let (:failing_oidc_client) do
    double('OidcClient').tap do |client|
      allow(client).to receive(:oidc_id_token_details).and_raise('FAKE_OIDC_ERROR')
    end
  end

  let (:failing_oidc_client_class) do
    double('OidcClientClass').tap do |client_class|
      allow(client_class).to receive(:new).and_return(failing_oidc_client)
    end
  end

  ####################################
  # request mock
  ####################################

  let (:oidc_login_request) do
    request_body = StringIO.new
    request_body.puts "code=some-code&redirect_uri=some-redirect-uri"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An oidc authenticator" do
    context "that recieves login request" do
      before(:each) do
        allow(mocked_oidc_authenticator).to receive(:call)
                                              .and_return(true)
      end

      context "with valid oidc details" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            oidc_login_request
          )

          ::Authentication::AuthnOidc::GetConjurOidcToken::ConjurOidcToken.new(
            oidc_authenticator:     mocked_oidc_authenticator,
            oidc_client_class:      oidc_client_class,
            enabled_authenticators: oidc_authenticator_name,
            token_factory:          oidc_token_factory,
            validate_security:      mocked_security_validator,
            validate_origin:        mocked_origin_validator
          ).(
            authenticator_input: input_
          )
        end

        it "returns a new oidc conjur token" do
          expect(subject).to equal(a_new_token)
        end

        it_behaves_like "raises an error when security validation fails"
        it_behaves_like "raises an error when origin validation fails"

        it_behaves_like "it fails when variable is missing or has no value", "client-id"
        it_behaves_like "it fails when variable is missing or has no value", "client-secret"
        it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
      end

      context "and fails on oidc details retrieval" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            oidc_login_request
          )

          ::Authentication::AuthnOidc::GetConjurOidcToken::ConjurOidcToken.new(
            oidc_authenticator:     mocked_oidc_authenticator,
            oidc_client_class:      failing_oidc_client_class,
            enabled_authenticators: oidc_authenticator_name,
            token_factory:          oidc_token_factory,
            validate_security:      mocked_security_validator,
            validate_origin:        mocked_origin_validator
          ).(
            authenticator_input: input_
          )
        end

        it "raises the actual oidc error" do
          expect { subject }.to raise_error(
                                  /FAKE_OIDC_ERROR/
                                )
        end
      end
    end
  end
end
