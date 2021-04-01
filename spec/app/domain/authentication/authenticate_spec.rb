# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::Authenticate') do
  include_context "security mocks"

  ####################################
  # Available Authenticators - doubles
  ####################################

  def authenticator(pass:)
    double('Authenticator').tap do |x|
      allow(x).to receive(:valid?).and_return(pass)
    end
  end

  let(:authenticators) do
    {
      'authn-always-pass' => authenticator(pass: true),
      'authn-always-fail' => authenticator(pass: false)
    }
  end

  ####################################
  # ENV doubles
  ####################################

  let(:two_authenticator_env) do
    { 'CONJUR_AUTHENTICATORS' => 'authn-always-pass, authn-always-fail' }
  end

  let(:blank_env) { {} }

  ####################################
  # TokenFactory double
  ####################################

  # NOTE: For _this_ class, the details of actual Conjur tokens are irrelevant
  #
  let(:a_new_token) { 'A NICE NEW TOKEN' }

  let(:mocked_token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

  ####################################
  # AuditEvent double
  ####################################

  let(:audit_success) { true }
  let(:mocked_audit_logger) do
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
        service_id: nil,
        account: 'my-acct',
        username: 'my-user',
        credentials: 'my-pw',
        client_ip: '127.0.0.1',
        request: nil
      )

      Authentication::Authenticate.new(
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
        validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true),
        validate_origin: mocked_origin_validator,
        token_factory: mocked_token_factory,
        audit_log: mocked_audit_logger
      ).call(
        authenticator_input: input_,
        authenticators: authenticators,
        enabled_authenticators: two_authenticator_env
      )
    end

    it "raises AuthenticatorNotSupported" do
      expect { subject }.to(
        raise_error(
          Errors::Authentication::AuthenticatorNotSupported
        )
      )
    end
  end

  context "An available authenticator" do
    context "that receives invalid credentials" do
      let(:audit_success) { false }
      subject do
        input_ = Authentication::AuthenticatorInput.new(
          authenticator_name: 'authn-always-fail',
          service_id: nil,
          account: 'my-acct',
          username: 'my-user',
          credentials: 'my-pw',
          client_ip: '127.0.0.1',
          request: nil
        )

        Authentication::Authenticate.new(
          validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
          validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true),
          validate_origin: mocked_origin_validator,
          token_factory: mocked_token_factory,
          audit_log: mocked_audit_logger
        ).call(
          authenticator_input: input_,
          authenticators: authenticators,
          enabled_authenticators: two_authenticator_env
        )
      end

      it "raises InvalidCredentials" do
        expect { subject }.to(
          raise_error(
            Errors::Authentication::InvalidCredentials
          )
        )
      end
    end

    context "that receives valid credentials" do
      context "with an inaccessible webservice" do
        let(:audit_success) { true }

        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-always-pass',
            service_id: nil,
            account: 'my-acct',
            username: 'my-user',
            credentials: 'my-pw',
            client_ip: '127.0.0.1',
            request: nil
          )

          Authentication::Authenticate.new(
            validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: false),
            validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true),
            validate_origin: mocked_origin_validator,
            token_factory: mocked_token_factory,
            audit_log: mocked_audit_logger
          ).call(
            authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env
          )
        end

        it "raises an error" do
          expect { subject }.to(
            raise_error(
              validate_role_can_access_webservice_error
            )
          )
        end
      end

      context "with a non-whitelisted webservice" do
        let(:audit_success) { true }

        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-always-pass',
            service_id: nil,
            account: 'my-acct',
            username: 'my-user',
            credentials: 'my-pw',
            client_ip: '127.0.0.1',
            request: nil
          )

          Authentication::Authenticate.new(
            validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
            validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: false),
            validate_origin: mocked_origin_validator,
            token_factory: mocked_token_factory,
            audit_log: mocked_audit_logger
          ).call(
            authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env
          )
        end

        it "raises an error" do
          expect { subject }.to(
            raise_error(
              validate_webservice_is_whitelisted_error
            )
          )
        end
      end

      context "when webservice validations succeed" do
        let(:audit_success) { true }

        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-always-pass',
            service_id: nil,
            account: 'my-acct',
            username: 'my-user',
            credentials: 'my-pw',
            client_ip: '127.0.0.1',
            request: nil
          )

          Authentication::Authenticate.new(
            validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
            validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true),
            validate_origin: mocked_origin_validator,
            token_factory: mocked_token_factory,
            audit_log: mocked_audit_logger
          ).call(
            authenticator_input: input_,
            authenticators: authenticators,
            enabled_authenticators: two_authenticator_env
          )
        end

        it "returns a new token" do
          expect(subject).to(
            equal(
              a_new_token
            )
          )
        end

        it_behaves_like "raises an error when origin validation fails"
      end
    end
  end
end
