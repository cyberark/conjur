# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe 'Authentication::Oidc' do

  let(:account) { "my-acct" }
  let(:service) { "my-service" }

  ####################################
  # env double
  ####################################

  let(:oidc_authenticator_name) { "authn-oidc-test" }

  ####################################
  # TokenFactory double
  ####################################

  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # secrets
  ####################################

  let (:mocked_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("mocked-secret")
    end
  end

  let (:mocked_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_secret)
    end
  end

  let (:resource_without_value) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(nil)
    end
  end

  let (:mocked_id_token_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("id_token_username_field")
    end
  end

  let (:mocked_id_token_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_id_token_secret)
    end
  end

  shared_examples_for "it fails when variable is missing or has no value" do |variable|
    it "fails when variable is missing" do
      allow(Resource).to receive(:[])
                           .with(/#{account}:variable:conjur\/authn-oidc\/#{service}\/#{variable}/)
                           .and_return(nil)

      expect { subject }.to raise_error(Conjur::RequiredResourceMissing)
    end

    it "fails when variable has no value" do
      allow(Resource).to receive(:[])
                           .with(/#{account}:variable:conjur\/authn-oidc\/#{service}\/#{variable}/)
                           .and_return(resource_without_value)

      expect { subject }.to raise_error(Conjur::RequiredSecretMissing)
    end
  end

  ####################################
  # authenticator & validators
  ####################################

  let (:mocked_security_validator) { double("MockSecurityValidator") }
  let (:mocked_origin_validator) { double("MockOriginValidator") }
  let (:mocked_decode_and_verify_id_token) { double("MockIdTokenDecodeAndVerify") }

  shared_examples_for "raises an error when security validation fails" do
    it 'raises an error when security validation fails' do
      allow(mocked_security_validator).to receive(:call)
                                            .and_raise('FAKE_SECURITY_ERROR')

      expect { subject }.to raise_error(
                              /FAKE_SECURITY_ERROR/
                            )
    end
  end

  shared_examples_for "raises an error when origin validation fails" do
    it "raises an error when origin validation fails" do
      allow(mocked_origin_validator).to receive(:call)
                                          .and_raise('FAKE_ORIGIN_ERROR')

      expect { subject }.to raise_error(
                              /FAKE_ORIGIN_ERROR/
                            )
    end
  end

  before(:each) do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc/)
                         .and_return(mocked_resource)

    allow(mocked_security_validator).to receive(:call)
                                          .and_return(true)

    allow(mocked_origin_validator).to receive(:call)
                                        .and_return(true)

    allow(mocked_decode_and_verify_id_token).to receive(:call)  { |*args|
      JSON.parse(args[0][:id_token_jwt]).to_hash
    }
  end

  ####################################
  # oidc request mock
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
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::AuthenticateIdToken::Authenticate.new(
              enabled_authenticators: oidc_authenticator_name,
              token_factory:          token_factory,
              validate_security:      mocked_security_validator,
              validate_origin:        mocked_origin_validator,
              decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).(
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
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            no_field_oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::AuthenticateIdToken::Authenticate.new(
              enabled_authenticators: oidc_authenticator_name,
              token_factory:          token_factory,
              validate_security:      mocked_security_validator,
              validate_origin:        mocked_origin_validator,
              decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Authentication::AuthnOidc::IdTokenFieldNotFound)
        end
      end

      context "with empty id token username value in id token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc-test',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            password:           nil,
            origin:             '127.0.0.1',
            request:            no_value_oidc_authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::AuthenticateIdToken::Authenticate.new(
              enabled_authenticators: oidc_authenticator_name,
              token_factory:          token_factory,
              validate_security:      mocked_security_validator,
              validate_origin:        mocked_origin_validator,
              decode_and_verify_id_token: mocked_decode_and_verify_id_token
          ).(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Authentication::AuthnOidc::IdTokenFieldNotFound)
        end
      end
    end
  end
end
