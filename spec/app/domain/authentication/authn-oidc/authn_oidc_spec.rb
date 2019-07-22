# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Authentication::Oidc' do

  include_context "oidc setup"

  let (:mocked_decode_and_verify_id_token) { double("MockIdTokenDecodeAndVerify") }

  before(:each) do
    allow(mocked_decode_and_verify_id_token).to receive(:call) { |*args|
      JSON.parse(args[0][:id_token_jwt]).to_hash
    }
  end

  ####################################
  # request mock
  ####################################

  let (:oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={\"id_token_username_field\": \"alice\"}"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:no_field_oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={}"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:no_value_oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={\"id_token_username_field\": \"\"}"
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
    context "that receives authenticate id token request" do
      before(:each) do
        allow(Resource).to receive(:[])
                             .with(/#{account}:variable:conjur\/authn-oidc\/#{service}\/id-token-user-property/)
                             .and_return(mocked_id_token_resource)
      end

      context "with valid id token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id: 'my-service',
            account: 'my-acct',
            username: nil,
            password: nil,
            origin: '127.0.0.1',
            request: oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::Authenticate.new(
            enabled_authenticators: oidc_authenticator_name,
            token_factory: token_factory,
            validate_security: mocked_security_validator,
            validate_origin: mocked_origin_validator,
            decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).call(
            authenticator_input: input_
          )
        end

        it "returns a new access token" do
          expect(subject).to equal(a_new_token)
        end

        it_behaves_like "raises an error when security validation fails"
        it_behaves_like "raises an error when origin validation fails"

        it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
        it_behaves_like "it fails when variable is missing or has no value", "id-token-user-property"
      end

      context "with no id token username field in id token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id: 'my-service',
            account: 'my-acct',
            username: nil,
            password: nil,
            origin: '127.0.0.1',
            request: no_field_oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::Authenticate.new(
            enabled_authenticators: oidc_authenticator_name,
            token_factory: token_factory,
            validate_security: mocked_security_validator,
            validate_origin: mocked_origin_validator,
            decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).call(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty)
        end
      end

      context "with empty id token username value in id token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id: 'my-service',
            account: 'my-acct',
            username: nil,
            password: nil,
            origin: '127.0.0.1',
            request: no_value_oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::Authenticate.new(
            enabled_authenticators: oidc_authenticator_name,
            token_factory: token_factory,
            validate_security: mocked_security_validator,
            validate_origin: mocked_origin_validator,
            decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).call(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty)
        end
      end
    end
  end
end
