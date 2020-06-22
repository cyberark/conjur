# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWebserviceIsWhitelisted do
  include_context "security mocks"

  let (:blank_env) { nil }
  let (:not_including_env) do
    "authn-other/service1"
  end

  let(:default_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn")
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
                                    .with(anything, two_authenticator_env)
                                    .and_return(webservices_dict(includes_authenticator: true))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, not_including_env)
                                    .and_return(webservices_dict(includes_authenticator: false))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, blank_env)
                                    .and_return(webservices_dict(includes_authenticator: false))
    end
  end

  let(:webservice_mock) {
    mock_webservice(test_account, fake_authenticator_name, "service1")
  }

  context "A whitelisted webservice" do
    subject do
      Authentication::Security::ValidateWebserviceIsWhitelisted.new(
        role_class:              mock_role_class,
        webservices_class:       mock_webservices_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice:             webservice_mock,
        account:                test_account,
        enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A un-whitelisted webservice" do
    subject do
      Authentication::Security::ValidateWebserviceIsWhitelisted.new(
        role_class:              mock_role_class,
        webservices_class:       mock_webservices_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice:             webservice_mock,
        account:                test_account,
        enabled_authenticators: not_including_env
      )
    end

    it "raises a AuthenticatorNotWhitelisted error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::AuthenticatorNotWhitelisted)
    end
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    subject do
      Authentication::Security::ValidateWebserviceIsWhitelisted.new(
        role_class:              mock_role_class,
        webservices_class:       mock_webservices_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice:             default_authenticator_mock,
        account:                test_account,
        enabled_authenticators: blank_env
      )
    end

    it "the default Conjur authenticator is included in whitelisted webservices" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateWebserviceIsWhitelisted.new(
        role_class:              mock_role_class,
        webservices_class:       mock_webservices_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
      ).call(
        webservice:             webservice_mock,
        account:                non_existing_account,
        enabled_authenticators: two_authenticator_env
      )
    end

    it "raises the error raised by validate_account_exists" do
      expect { subject }.to raise_error(validate_account_exists_error)
    end
  end
end
