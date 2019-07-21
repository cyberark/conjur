# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateSecurity do
  include_context "security mocks"

  let(:authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn-x")
    end
  end

  let(:mock_validate_whitelisted_webservice) { double("ValidateWhitelistedWebservice") }
  let(:mock_validate_webservice_access) { double("ValidateWebserviceAccess") }

  before(:each) do
    allow(Authentication::Security::ValidateWhitelistedWebservice)
      .to receive(:new)
            .and_return(mock_validate_whitelisted_webservice)
    allow(mock_validate_whitelisted_webservice).to receive(:call)
                                                .and_return(true)

    allow(Authentication::Security::ValidateWebserviceAccess)
      .to receive(:new)
            .and_return(mock_validate_webservice_access)
    allow(mock_validate_webservice_access).to receive(:call)
                                           .and_return(true)
  end

  context "A whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).call(
        webservice: authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A whitelisted, inaccessible webservice and authorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).call(
        webservice: authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises the error that is raised by validate_webservice_access" do
      allow(mock_validate_webservice_access)
        .to receive(:call)
              .and_raise("webservice-access-validation-error")

      expect { subject }.to raise_error("webservice-access-validation-error")
    end
  end

  context "An un-whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).call(
        webservice: authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises the error that is raised by validate_whitelisted_webservice" do

      allow(mock_validate_whitelisted_webservice)
        .to receive(:call)
              .and_raise("whitelisted-webservice-validation-error")

      expect { subject }.to raise_error("whitelisted-webservice-validation-error")
    end
  end
end
