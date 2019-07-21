# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWebserviceExists do
  include_context "security mocks"

  let (:mock_resource) { 'some-random-resource' }
  let (:non_existing_resource_id) { 'non-existing-resource' }

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
        webservice: mock_webservice("#{fake_authenticator_name}/service1"),
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
        webservice: mock_webservice(non_existing_resource_id),
          account: test_account
      )
    end

    it "raises a ServiceNotDefined error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::ServiceNotDefined)
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateWebserviceExists.new(
        role_class: mock_role_class,
        resource_class: mock_resource_class,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
      ).call(
        webservice: mock_webservice("#{fake_authenticator_name}/service1"),
          account: non_existing_account
      )
    end

    it "raises the error raised by validate_account_exists" do
      expect { subject }.to raise_error(validate_account_exists_error)
    end
  end
end
