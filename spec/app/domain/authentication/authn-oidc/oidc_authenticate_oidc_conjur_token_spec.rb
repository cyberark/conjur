# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Authentication::Oidc' do

  include_context "oidc setup"

  ####################################
  # authenticator & validators
  ####################################

  let (:failing_validate_and_decrypt_oidc_conjur_token) { double("MockGetOidcConjurToken") }

  ####################################
  # request mock
  ####################################

  let (:oidc_authenticate_conjur_oidc_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token_encrypted=some-id-token-encrypted&user_name=my-user&expiration_time=1234567"
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
    context "that receives authenticate oidc conjur token request" do
      context "with valid oidc conjur token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            oidc_authenticate_conjur_oidc_token_request
          )

          ::Authentication::AuthnOidc::AuthenticateOidcConjurToken::Authenticate.new(
            enabled_authenticators: oidc_authenticator_name,
            token_factory:          token_factory,
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
            request:            oidc_authenticate_conjur_oidc_token_request
          )

          ::Authentication::AuthnOidc::AuthenticateOidcConjurToken::Authenticate.new(
            validate_and_decrypt_oidc_conjur_token: failing_validate_and_decrypt_oidc_conjur_token,
            enabled_authenticators: oidc_authenticator_name,
            token_factory:          token_factory,
            validate_security:      mocked_security_validator,
            validate_origin:        mocked_origin_validator
          ).(
            authenticator_input: input_
          )
        end

        it "raises the actual oidc error" do
          allow(failing_validate_and_decrypt_oidc_conjur_token).to receive(:call)
                                                    .and_raise('FAKE_OIDC_ERROR')

          expect { subject }.to raise_error(
                                  /FAKE_OIDC_ERROR/
                                )
        end
      end
    end
  end
end
