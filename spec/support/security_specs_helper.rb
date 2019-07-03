# frozen_string_literal: true

require 'spec_helper'

shared_context "security mocks" do
  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }
  let (:fake_authenticator_name) { 'authn-x' }
  let (:test_user_id) { 'some-user' }
  let (:two_authenticator_env) { "#{fake_authenticator_name}/service1, #{fake_authenticator_name}/service2" }

  def mock_webservice(resource_id)
    double('webservice').tap do |webservice|
      allow(webservice).to receive(:authenticator_name)
                             .and_return("some-string")

      allow(webservice).to receive(:name)
                             .and_return("some-string")

      allow(webservice).to receive(:resource_id)
                             .and_return(resource_id)
    end
  end

  def mock_role_class
    double('role_class').tap do |role_class|
      allow(role_class).to receive(:username_from_roleid).and_return('some-username')

      allow(role_class).to receive(:[])
                             .with(/#{test_account}:user:admin/)
                             .and_return("admin-role")

      allow(role_class).to receive(:[])
                             .with(/#{non_existing_account}:user:admin/)
                             .and_return(nil)
    end
  end

  let (:validate_account_exists_error) { "validate account exists error" }
  let (:validate_whitelisted_webservice_error) { "validate whitelisted webservice error" }
  let (:validate_webservice_access_error) { "validate webservice access error" }
  let (:validate_webservice_exists_error) { "validate webservice exists error" }

  def mock_validator(validation_succeeded:, validation_error:)
    double('validator').tap do |validator|
      if validation_succeeded
        allow(validator).to receive(:call)
      else
        allow(validator).to receive(:call).and_raise(validation_error)
      end
    end
  end

  def mock_validate_account_exists(validation_succeeded:)
    mock_validator(validation_succeeded: validation_succeeded, validation_error: validate_account_exists_error)
  end

  def mock_validate_whitelisted_webservice(validation_succeeded:)
    mock_validator(validation_succeeded: validation_succeeded, validation_error: validate_whitelisted_webservice_error)
  end

  def mock_validate_webservice_access(validation_succeeded:)
    mock_validator(validation_succeeded: validation_succeeded, validation_error: validate_webservice_access_error)
  end

  def mock_validate_webservice_exists(validation_succeeded:)
    mock_validator(validation_succeeded: validation_succeeded, validation_error: validate_webservice_exists_error)
  end

  # generates user_role authorized for all or no services
  def user_role(is_authorized:)
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(is_authorized)
      allow(role).to receive(:role_id).and_return('some-role-id')
    end
  end

  def mock_role
    double('user_role').tap do |role|
      allow(role).to receive(:role_id).and_return('some-role-id')
    end
  end
end
