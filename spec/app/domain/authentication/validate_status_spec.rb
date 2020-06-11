# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::ValidateStatus do
  include_context "security mocks"

  let (:mock_enabled_authenticators) do
    "authn-status-pass,authn-status-not-implemented"
  end

  let (:not_including_enabled_authenticators) do
    "authn-other"
  end

  def authenticator_class(is_status_defined)
    double('authenticator_class').tap do |authenticator_class|
      allow(authenticator_class).to receive(:method_defined?)
                                      .with(:status)
                                      .and_return(is_status_defined)
    end
  end

  def authenticator(is_status_defined:, is_failing_requirements:)
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:class)
                                .and_return(authenticator_class(is_status_defined))

      if is_failing_requirements
        allow(authenticator).to receive(:status)
                                  .and_raise("specific-authn-error")
      else
        allow(authenticator).to receive(:status)
      end
    end
  end

  def mock_status_webservice(resource_id)
    double('status_webservice').tap do |status_webservice|
      allow(status_webservice).to receive(:name)
                                    .and_return("some-string")

      allow(status_webservice).to receive(:resource_id)
                                    .and_return("#{resource_id}/status")

      allow(status_webservice).to receive(:parent_webservice)
                             .and_return(mock_webservice(resource_id))
    end
  end

  def mock_webservice(resource_id)
    double('webservice').tap do |webservice|
      allow(webservice).to receive(:name)
                             .and_return("some-string")

      allow(webservice).to receive(:resource_id)
                             .and_return(resource_id)
    end
  end

  def webservices_dict(includes_authenticator:)
    double('webservices_dict').tap do |webservices_dict|
      allow(webservices_dict).to receive(:include?)
                                   .and_return(includes_authenticator)
    end
  end

  def mock_webservices_class
    double('webservices_class').tap do |webservices_class|
      allow(webservices_class).to receive(:from_string)
                                    .with(anything, mock_enabled_authenticators)
                                    .and_return(webservices_dict(includes_authenticator: true))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, not_including_enabled_authenticators)
                                    .and_return(webservices_dict(includes_authenticator: false))
    end
  end

  let(:audit_logger) do
    double('audit_logger').tap do |logger|
      expect(logger).to receive(:log)
    end
  end

  let (:mock_implemented_authenticators) do
    {
      'authn-status-pass' => authenticator(is_status_defined: true, is_failing_requirements: false),
      'authn-status-not-implemented' => authenticator(is_status_defined: false, is_failing_requirements: false),
      'authn-status-fail' => authenticator(is_status_defined: true, is_failing_requirements: true)
    }
  end

  def mock_status_input(authenticator_name)
    double('status_input').tap do |status_input|
      allow(status_input).to receive(:authenticator_name)
                                    .and_return(authenticator_name)

      allow(status_input).to receive(:account)
                                    .and_return(test_account)

      allow(status_input).to receive(:status_webservice)
                               .and_return(mock_status_webservice(authenticator_name))

      allow(status_input).to receive(:webservice)
                               .and_return(mock_webservice(authenticator_name))

      allow(status_input).to receive(:username)
                               .and_return(test_user_id)

      allow(status_input).to receive(:role)
                               .and_return(mock_role_class)
    end
  end

  context "A valid, whitelisted authenticator" do

    subject do
      Authentication::ValidateStatus.new(
        role_class: mock_role_class,
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice(validation_succeeded: true),
        validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        implemented_authenticators: mock_implemented_authenticators,
        audit_log: audit_logger
      ).call(
        authenticator_status_input: mock_status_input("authn-status-pass"),
        enabled_authenticators: mock_enabled_authenticators
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing authenticator" do
    subject do
      Authentication::ValidateStatus.new(
        role_class: mock_role_class,
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice(validation_succeeded: true),
        validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        implemented_authenticators: mock_implemented_authenticators,
        audit_log: audit_logger
      ).call(
        authenticator_status_input: mock_status_input("authn-non-exist"),
        enabled_authenticators: mock_enabled_authenticators
      )
    end

    it "raises an AuthenticatorNotFound error" do
      expect { subject }.to raise_error(Errors::Authentication::AuthenticatorNotFound)
    end
  end


  context "An existing authenticator" do
    context "that does not implement the status check" do

      subject do
        Authentication::ValidateStatus.new(
          role_class: mock_role_class,
          validate_whitelisted_webservice: mock_validate_whitelisted_webservice(validation_succeeded: true),
          validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
          validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
          implemented_authenticators: mock_implemented_authenticators,
          audit_log: audit_logger
        ).call(
          authenticator_status_input: mock_status_input("authn-status-not-implemented"),
          enabled_authenticators: mock_enabled_authenticators
        )
      end

      it "raises a StatusNotImplemented error" do
        expect { subject }.to raise_error(Errors::Authentication::StatusNotImplemented)
      end
    end

    context "that implements the status check" do

      context "where the user doesn't have access to the status check" do

        subject do
          Authentication::ValidateStatus.new(
            role_class: mock_role_class,
            validate_whitelisted_webservice: mock_validate_webservice_exists(validation_succeeded: true),
            validate_webservice_access: mock_validate_webservice_access(validation_succeeded: false),
            validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
            implemented_authenticators: mock_implemented_authenticators,
            audit_log: audit_logger
          ).call(
            authenticator_status_input: mock_status_input("authn-status-pass"),
            enabled_authenticators: mock_enabled_authenticators
          )
        end

        it "raises the error raised by validate_webservice_access" do
          expect { subject }.to raise_error(validate_webservice_access_error)
        end

      end

      context "where the user has access to the status check" do

        context "with a non-existing authenticator webservice" do

          subject do
            Authentication::ValidateStatus.new(
              role_class: mock_role_class,
              validate_whitelisted_webservice: mock_validate_webservice_exists(validation_succeeded: true),
              validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
              validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: false),
              implemented_authenticators: mock_implemented_authenticators,
              audit_log: audit_logger
            ).call(
              authenticator_status_input: mock_status_input("authn-status-pass"),
              enabled_authenticators: mock_enabled_authenticators
            )
          end

          it "raises the error raised by validate_webservice_exists" do
            expect { subject }.to raise_error(validate_webservice_exists_error)
          end

        end

        context "with an existing authenticator webservice" do

          context "and the authenticator is not whitelisted" do

            subject do
              Authentication::ValidateStatus.new(
                role_class: mock_role_class,
                validate_whitelisted_webservice: mock_validate_whitelisted_webservice(validation_succeeded: false),
                validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
                validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
                implemented_authenticators: mock_implemented_authenticators,
                audit_log: audit_logger
              ).call(
                authenticator_status_input: mock_status_input("authn-status-pass"),
                enabled_authenticators: not_including_enabled_authenticators
              )
            end

            it "raises the error raised by validate_whitelisted_webservice" do
              expect { subject }.to raise_error(validate_whitelisted_webservice_error)
            end
          end

          context "and the authenticator is whitelisted" do

            context "with failing specific requirements" do
              subject do
                Authentication::ValidateStatus.new(
                  role_class: mock_role_class,
                  validate_whitelisted_webservice: mock_validate_webservice_exists(validation_succeeded: true),
                  validate_webservice_access: mock_validate_webservice_access(validation_succeeded: true),
                  validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
                  implemented_authenticators: mock_implemented_authenticators,
                  audit_log: audit_logger
                ).call(
                  authenticator_status_input: mock_status_input("authn-status-fail"),
                  enabled_authenticators: mock_enabled_authenticators
                )
              end

              it "raises the same error" do
                expect { subject }.to raise_error("specific-authn-error")
              end
            end
          end
        end
      end
    end
  end
end
