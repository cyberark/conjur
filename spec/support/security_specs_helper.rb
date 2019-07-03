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

  def mock_admin_role_class
    double('role_class').tap do |role_class|
      allow(role_class).to receive(:[])
                             .with(/#{test_account}:user:admin/)
                             .and_return("admin-role")

      allow(role_class).to receive(:[])
                             .with(/#{non_existing_account}:user:admin/)
                             .and_return(nil)
    end
  end

  let (:account_not_exist_error) { "account doesn't exist" }

  def mock_validate_account_exists(is_failing:)
    double('validate_account_exists').tap do |validate_account_exists|
      if is_failing
        allow(validate_account_exists).to receive(:call).and_raise(account_not_exist_error)
      else
        allow(validate_account_exists).to receive(:call)
      end
    end
  end
end
