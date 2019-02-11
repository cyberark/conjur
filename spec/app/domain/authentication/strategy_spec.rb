# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Input#to_access_request' do
  let (:two_authenticator_env) { "authn-one, authn-two" }

  let (:blank_env) { nil }

  subject do
    Authentication::Input.new(
      authenticator_name: 'authn-test',
      service_id: 'my-service',
      account: 'my-acct',
      username: 'someuser',
      password: 'secret',
      origin: '127.0.0.1',
      request: nil
    )
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    it "whitelists only the default Conjur authenticator" do
      services = subject.to_access_request(blank_env).whitelisted_webservices
      expect(services.to_a.size).to eq(1)
      expect(services.first.name).to eq(
                                       Authentication::Common.default_authenticator_name
                                     )
    end
  end

  context "An ENV containing CONJUR_AUTHENTICATORS" do
    it "whitelists exactly those authenticators as webservices" do
      services = subject
                   .to_access_request(two_authenticator_env)
                   .whitelisted_webservices
                   .map(&:name)
      expect(services).to eq(['authn-one', 'authn-two'])
    end
  end

  it "passes the username through as the user_id" do
    access_request = subject.to_access_request(blank_env)
    expect(access_request.user_id).to eq(subject.username)
  end

  context "An input with a service_id" do
    it "creates a Webservice with the correct authenticator_name" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.authenticator_name).to eq(subject.authenticator_name)
    end

    it "creates a Webservice with the correct service_id" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.service_id).to eq(subject.service_id)
    end

    it "creates a Webservice with the correct account" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.account).to eq(subject.account)
    end
  end

  context "An input without a service_id" do
    subject do
      Authentication::Input.new(
        authenticator_name: 'authn-test',
        service_id: nil,
        account: 'my-acct',
        username: 'someuser',
        password: 'secret',
        origin: '127.0.0.1',
        request: nil
      )
    end

    it "creates a Webservice without a service_id" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.service_id).to be_nil
    end
  end
end

RSpec.describe 'Authentication::Strategy' do
  ####################################
  # Available Authenticators - doubles
  ####################################

  def authenticator(pass:)
    double('Authenticator').tap do |x|
      allow(x).to receive(:valid?).and_return(pass)
    end
  end

  def input(
    authenticator_name: 'authn-always-pass',
    service_id: nil,
    account: 'my-acct',
    username: 'my-user',
    password: 'my-pw',
    origin: '127.0.0.1',
    request: nil
  )
    Authentication::Input.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: username,
      password: password,
      origin: origin,
      request: request
    )
  end

  let (:authenticators) do
    {
      'authn-always-pass' => authenticator(pass: true),
      'authn-always-fail' => authenticator(pass: false)
    }
  end

  ####################################
  # Security doubles
  ####################################

  let (:mocked_security_validator) {double("MockSecurityValidator")}
  let (:mocked_origin_validator) {double("MockOriginValidator")}

  before(:each) do
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
  # ENV doubles
  ####################################

  let (:two_authenticator_env) do
    {'CONJUR_AUTHENTICATORS' => 'authn-always-pass, authn-always-fail'}
  end

  let (:blank_env) {Hash.new}

  ####################################
  # TokenFactory double
  ####################################

  # NOTE: For _this_ class, the details of actual Conjur tokens are irrelevant
  #
  let (:a_new_token) {'A NICE NEW TOKEN'}

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/


  context "An unavailable authenticator" do
    subject do
      input_ = input(
        authenticator_name: 'AUTHN-MISSING'
      )

      Authentication::Authenticate.new.(
        authenticator_input: input_,
          authenticators: authenticators,
          enabled_authenticators: two_authenticator_env,
          token_factory: token_factory
      )
    end

    it "raises AuthenticatorNotFound" do
      expect {subject}.to raise_error(
                            Authentication::AuthenticatorNotFound
                          )
    end
  end

  context "An available authenticator" do
    context "that receives invalid credentials" do
      subject do
        input_ = input(
          authenticator_name: 'authn-always-fail'
        )

        Authentication::Authenticate.new.(
          authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env,
            token_factory: token_factory
        )
      end

      it "raises InvalidCredentials" do
        expect {subject}.to raise_error(
                              Authentication::InvalidCredentials
                            )
      end
    end

    context "that receives valid credentials" do
      subject do
        input_ = input(
          authenticator_name: 'authn-always-pass'
        )

        Authentication::Authenticate.new.(
          authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env,
            token_factory: token_factory
        )
      end

      it "returns a new token" do
        expect(subject).to equal(a_new_token)
      end
    end

    context "that receives valid credentials" do
      subject do
        input_ = input(
          authenticator_name: 'authn-always-pass'
        )

        Authentication::Authenticate.new.(
          authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env,
            token_factory: token_factory
        )
      end

      it "raises an error when security fails" do
        allow(mocked_security_validator).to receive(:call)
                                              .and_raise('FAKE_SECURITY_ERROR')

        expect {subject}.to raise_error(
                                                   /FAKE_SECURITY_ERROR/
                                                 )
      end
    end
  end
end
