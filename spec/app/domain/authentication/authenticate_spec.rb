# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Authenticate' do
  ####################################
  # Available Authenticators - doubles
  ####################################

  def authenticator(pass:)
    double('Authenticator').tap do |x|
      allow(x).to receive(:valid?).and_return(pass)
    end
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

  let (:mocked_security_validator) { double("MockSecurityValidator") }
  let (:mocked_origin_validator) { double("MockOriginValidator") }

  before(:each) do
    allow(Authentication::Security::ValidateSecurity)
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
    { 'CONJUR_AUTHENTICATORS' => 'authn-always-pass, authn-always-fail' }
  end

  let (:blank_env) { Hash.new }

  ####################################
  # TokenFactory double
  ####################################

  # NOTE: For _this_ class, the details of actual Conjur tokens are irrelevant
  #
  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # AuditEvent double
  ####################################

  let(:audit_success) { true }
  let(:audit_logger) do
    double('audit_logger').tap do |logger|
      expect(logger).to receive(:log)
    end
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/


  context "An unavailable authenticator" do
    let(:audit_success) { false }
    subject do
      input_ = Authentication::AuthenticatorInput.new(
        authenticator_name: 'AUTHN-MISSING',
        service_id:         nil,
        account:            'my-acct',
        username:           'my-user',
        credentials:        'my-pw',
        origin:             '127.0.0.1',
        request:            nil
      )

      Authentication::Authenticate.new(
        token_factory: token_factory,
        audit_log: audit_logger
      ).call(
        authenticator_input:    input_,
        authenticators:         authenticators,
        enabled_authenticators: two_authenticator_env
      )
    end

    it "raises AuthenticatorNotFound" do
      expect { subject }.to raise_error(
                              Errors::Authentication::AuthenticatorNotFound
                            )
    end
  end

  context "An available authenticator" do
    context "that receives invalid credentials" do
      let(:audit_success) { false }
      subject do
        input_ = Authentication::AuthenticatorInput.new(
          authenticator_name: 'authn-always-fail',
          service_id:         nil,
          account:            'my-acct',
          username:           'my-user',
          credentials:        'my-pw',
          origin:             '127.0.0.1',
          request:            nil
        )

        Authentication::Authenticate.new(
          token_factory: token_factory,
          audit_log: audit_logger
        ).call(
          authenticator_input:    input_,
          authenticators:         authenticators,
          enabled_authenticators: two_authenticator_env
        )
      end

      it "raises InvalidCredentials" do
        expect { subject }.to raise_error(
                                Errors::Authentication::InvalidCredentials
                              )
      end
    end

    context "that receives valid credentials" do
      let(:audit_success) { true }

      subject do
        input_ = Authentication::AuthenticatorInput.new(
          authenticator_name: 'authn-always-pass',
          service_id:         nil,
          account:            'my-acct',
          username:           'my-user',
          credentials:        'my-pw',
          origin:             '127.0.0.1',
          request:            nil
        )

        Authentication::Authenticate.new(
          token_factory: token_factory,
          audit_log: audit_logger
        ).call(
          authenticator_input:    input_,
          authenticators:         authenticators,
          enabled_authenticators: two_authenticator_env
        )
      end

      it "returns a new token" do
        expect(subject).to equal(a_new_token)
      end

      context "when security fails" do
        let(:audit_success) { false }

        it "raises an error" do
          allow(mocked_security_validator).to receive(:call)
                                                .and_raise('FAKE_SECURITY_ERROR')

          expect { subject }.to raise_error(
                                  /FAKE_SECURITY_ERROR/
                                )
        end
      end

      context "when origin validation fails" do
        let(:audit_success) { false }

        it "raises an error" do
          allow(mocked_origin_validator).to receive(:call)
                                              .and_raise('FAKE_ORIGIN_ERROR')

          expect { subject }.to raise_error(
                                  /FAKE_ORIGIN_ERROR/
                                )
        end
      end
    end
  end
end
