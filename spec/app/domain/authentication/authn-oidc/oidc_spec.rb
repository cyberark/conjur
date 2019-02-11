# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Oidc' do

  ####################################
  # authentication input mock
  ####################################

  def input(
    authenticator_name: 'authn-oidc-test',
    service_id: nil,
    account: 'my-acct',
    origin: '127.0.0.1',
    request: nil
  )
    Authentication::Input.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      origin: origin,
      request: request
    )
  end

  let(:username) {"my-user"}
  let(:account) {"my-acct"}

  ####################################
  # env double
  ####################################

  let (:oidc_authenticator_env) do
    {'CONJUR_AUTHENTICATORS' => 'authn-oidc-test'}
  end

  ####################################
  # TokenFactory double
  ####################################

  let (:a_new_token) {'A NICE NEW TOKEN'}

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

  let (:mocked_oidc_authenticator) {double("MockOidcAuthenticator")}
  let (:mocked_security_validator) {double("MockSecurityValidator")}
  let (:mocked_origin_validator) {double("MockOriginValidator")}

  before(:each) do
    allow(Resource).to receive(:[])
                         .with(/#{account}:variable:conjur\/authn-oidc/)
                         .and_return(mocked_resource)

    allow(Authentication::AuthnOidc::Authenticator)
      .to receive(:new)
            .and_return(mocked_oidc_authenticator)
    allow(mocked_oidc_authenticator).to receive(:call)
                                          .and_return(true)

    allow(Authentication::ValidateSecurity)
      .to receive(:new)
            .and_return(mocked_security_validator)
    allow(mocked_security_validator).to receive(:call)
                                          .and_return(true)

    allow(Authentication::ValidateOrigin)
      .to receive(:new)
            .and_return(mocked_origin_validator)
    allow(mocked_origin_validator).to receive(:call)
                                        .and_return(true)
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

  let (:oidc_authenticate_request) do
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
    context "that receives login request with valid oidc details" do
      subject do
        input_ = input(
          request: oidc_login_request
        )

        ::Authentication::AuthnOidc::Login.new.(
          authenticator_input: input_,
            oidc_client_class: oidc_client_class,
            env: oidc_authenticator_env,
            token_factory: oidc_token_factory
        )
      end

      it "returns a new oidc conjur token" do
        expect(subject).to equal(a_new_token)
      end
    end

    context "that receives authenticate request with valid oidc conjur token" do
      subject do
        input_ = input(
          request: oidc_authenticate_request
        )

        ::Authentication::AuthnOidc::Authenticate.new.(
          authenticator_input: input_,
            env: oidc_authenticator_env,
            token_factory: token_factory
        )
      end

      it "returns a new oidc conjur token" do
        expect(subject).to equal(a_new_token)
      end
    end
  end
end
