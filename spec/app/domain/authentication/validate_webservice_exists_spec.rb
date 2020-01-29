# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWebserviceExists do
  include_context "security mocks"

  let (:mock_resource) { 'some-random-resource' }
  let (:non_existing_authenticator_name) { 'non-existing-authenticator' }
  let (:non_existing_service_id) { 'non-existing-service' }
  let (:non_existing_resource_id) {
    "#{test_account}:webservice:conjur/#{non_existing_authenticator_name}/#{non_existing_service_id}"
  }

  def mock_resource_class
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(mock_resource)

      allow(resource_class).to receive(:[])
                                 .with(non_existing_resource_id)
                                 .and_return(nil)
    end
  end

  context "An existing webservice" do
    subject do
      Authentication::Security::ValidateWebserviceExists.new(
        role_class: mock_role_class,
        resource_class: mock_resource_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: mock_webservice(test_account, fake_authenticator_name, "service1"),
        account: test_account
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing webservice" do
    subject do
      Authentication::Security::ValidateWebserviceExists.new(
        role_class: mock_role_class,
        resource_class: mock_resource_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: mock_webservice(test_account, non_existing_authenticator_name, non_existing_service_id),
        account: test_account
      )
    end

    it "raises a WebserviceNotFound error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::WebserviceNotFound)
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateWebserviceExists.new(
        role_class: mock_role_class,
        resource_class: mock_resource_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
      ).call(
        webservice: mock_webservice(test_account, fake_authenticator_name, "service1"),
        account: non_existing_account
      )
    end

    it "raises the error raised by validate_account_exists" do
      expect { subject }.to raise_error(validate_account_exists_error)
    end
  end
end
