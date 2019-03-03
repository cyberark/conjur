# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Oidc' do

  let(:username) { "my-user" }
  let(:account) { "my-acct" }

  ####################################
  # env double
  ####################################

  let(:oidc_authenticator_name) { "authn-oidc-test" }

  ####################################
  # TokenFactory double
  ####################################

  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:oidc_token_factory) do
    double('OidcTokenFactory').tap do |factory|
      allow(factory).to receive(:oidc_token).and_return(a_new_token)
    end
  end

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # secrets double
  ####################################

  let (:mocked_secret) do
    double('Secret').tap do |secret|
      allow(secret).to receive(:value).and_return("secret")
    end
  end

  let (:mocked_resource) do
    double('Resource').tap do |resource|
      allow(resource).to receive(:secret).and_return(mocked_secret)
    end
  end

  ####################################
  # authenticator & validators
  ####################################

  let (:mocked_oidc_authenticator) { double("MockOidcAuthenticator") }
  let (:mocked_security_validator) { double("MockSecurityValidator") }
  let (:mocked_origin_validator) { double("MockOriginValidator") }
  let (:failing_get_oidc_conjur_token) { double("MockGetOidcConjurToken") }

  before(:each) do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc/)
                         .and_return(mocked_resource)

    allow(mocked_oidc_authenticator).to receive(:call)
                                          .and_return(true)

    allow(mocked_security_validator).to receive(:call)
                                          .and_return(true)

    allow(mocked_origin_validator).to receive(:call)
                                        .and_return(true)

    allow(failing_get_oidc_conjur_token).to receive(:call)
                                             .and_raise('FAKE_OIDC_ERROR')
  end

  ####################################
  # oidc id token values
  ####################################

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
  # oidc mock
  ####################################

  let (:oidc_client) do
    double('OidcClient').tap do |client|
      allow(client).to receive(:oidc_id_token_details!).and_return(oidc_id_token_details)
    end
  end

  let (:oidc_client_class) do
    double('OidcClientClass').tap do |client_class|
      allow(client_class).to receive(:new).and_return(oidc_client)
    end
  end

  let (:failing_oidc_client) do
    double('OidcClient').tap do |client|
      allow(client).to receive(:oidc_id_token_details!).and_raise('FAKE_OIDC_ERROR')
    end
  end

  let (:failing_oidc_client_class) do
    double('OidcClientClass').tap do |client_class|
      allow(client_class).to receive(:new).and_return(failing_oidc_client)
    end
  end

  let (:oidc_client_configuration) do
    double('OidcClientConfiguration').tap do |client_configuration|
      allow(client_configuration).to receive(:id_token_user_property).and_return('preferred_username')
    end
  end

  let (:get_oidc_client_configuration) do
    double('GetOidcClientConfiguration').tap do |get_client_configuration|
      allow(get_client_configuration).to receive(:call)
                                           .and_return(oidc_client_configuration)
    end
  end

  ####################################
  # oidc request mock
  ####################################

  let (:oidc_login_request) do
    request_body = StringIO.new
    request_body.puts "code=some-code&redirect_uri=some-redirect-uri"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:oidc_authenticate_conjur_oidc_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token_encrypted=some-id-token-encrypted&user_name=my-user&expiration_time=1234567"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={\"preferred_username\": \"alice\",\"email\": \"alice@example.com\"}"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:no_preferred_username_field_oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={}"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:no_preferred_username_value_oidc_authenticate_id_token_request) do
    request_body = StringIO.new
    request_body.puts "id_token={\"preferred_username\": \"\"}"
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
    context "that receives login request with valid oidc details" do
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

        ::Authentication::AuthnOidc::Login.new(
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

      it "raises an error when security validation fails" do
        allow(mocked_security_validator).to receive(:call)
                                              .and_raise('FAKE_SECURITY_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_SECURITY_ERROR/
                              )
      end

      it "raises an error when origin validation fails" do
        allow(mocked_origin_validator).to receive(:call)
                                            .and_raise('FAKE_ORIGIN_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_ORIGIN_ERROR/
                              )
      end
    end

    context "that receives login request and fails on oidc details retrieval" do
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

        ::Authentication::AuthnOidc::Login.new(
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

    context "that receives authenticate request with valid oidc conjur token" do
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

        ::Authentication::AuthnOidc::AuthenticateOidcConjurToken.new(
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

      it "raises an error when security validation fails" do
        allow(mocked_security_validator).to receive(:call)
                                              .and_raise('FAKE_SECURITY_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_SECURITY_ERROR/
                              )
      end

      it "raises an error when origin validation fails" do
        allow(mocked_origin_validator).to receive(:call)
                                            .and_raise('FAKE_ORIGIN_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_ORIGIN_ERROR/
                              )
      end
    end

    context "that receives authenticate request and fails on oidc details retrieval" do
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

        ::Authentication::AuthnOidc::AuthenticateOidcConjurToken.new(
          get_oidc_conjur_token: failing_get_oidc_conjur_token,
          enabled_authenticators: oidc_authenticator_name,
          token_factory:          token_factory,
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

    context "that receives authenticate request with valid id token" do
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

        ::Authentication::AuthnOidc::Authenticate.new(
          enabled_authenticators: oidc_authenticator_name,
          get_oidc_client_configuration: get_oidc_client_configuration,
          token_factory:          token_factory,
          validate_security:      mocked_security_validator,
          validate_origin:        mocked_origin_validator
        ).(
          authenticator_input: input_
        )
      end

      it "returns a new access token" do
        expect(subject).to equal(a_new_token)
      end

      it "raises an error when security validation fails" do
        allow(mocked_security_validator).to receive(:call)
                                              .and_raise('FAKE_SECURITY_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_SECURITY_ERROR/
                              )
      end

      it "raises an error when origin validation fails" do
        allow(mocked_origin_validator).to receive(:call)
                                            .and_raise('FAKE_ORIGIN_ERROR')

        expect { subject }.to raise_error(
                                /FAKE_ORIGIN_ERROR/
                              )
      end
    end

    context "that receives authenticate request with no preferred username in id token" do
      subject do
        input_ = Authentication::AuthenticatorInput.new(
          authenticator_name: 'authn-oidc-test',
          service_id:         'my-service',
          account:            'my-acct',
          username:           nil,
          password:           nil,
          origin:             '127.0.0.1',
          request:            no_preferred_username_field_oidc_authenticate_id_token_request
        )

        ::Authentication::AuthnOidc::Authenticate.new(
          enabled_authenticators: oidc_authenticator_name,
          get_oidc_client_configuration: get_oidc_client_configuration,
          token_factory:          token_factory,
          validate_security:      mocked_security_validator,
          validate_origin:        mocked_origin_validator
        ).(
          authenticator_input: input_
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(::Authentication::AuthnOidc::IdTokenFieldNotFound)
      end
    end

    context "that receives authenticate request with empty preferred username in id token" do
      subject do
        input_ = Authentication::AuthenticatorInput.new(
          authenticator_name: 'authn-oidc-test',
          service_id:         'my-service',
          account:            'my-acct',
          username:           nil,
          password:           nil,
          origin:             '127.0.0.1',
          request:            no_preferred_username_value_oidc_authenticate_id_token_request
        )

        ::Authentication::AuthnOidc::Authenticate.new(
          enabled_authenticators: oidc_authenticator_name,
          get_oidc_client_configuration: get_oidc_client_configuration,
          token_factory:          token_factory,
          validate_security:      mocked_security_validator,
          validate_origin:        mocked_origin_validator
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
