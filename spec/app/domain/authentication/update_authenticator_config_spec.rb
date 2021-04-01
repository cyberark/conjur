require 'spec_helper'

RSpec.describe(Authentication::UpdateAuthenticatorConfig) do
  include_context "security mocks"

  let(:authenticator_name) { "authn-test" }
  let(:service_id) { "test-service" }

  let(:mock_model) { double(::AuthenticatorConfig) }

  let(:call_params) do
    {
      account: test_account,
      authenticator_name: authenticator_name,
      service_id: service_id,
      enabled: true,
      username: test_user_id
    }
  end

  before do
    allow(mock_model)
      .to receive_message_chain(:find_or_create, :update)
      .and_return(1)
  end

  context "webservice resource exists and the current user has correct permissions" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: true),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true)
      ).call(call_params)
    end

    it "updates the config record of an authenticator" do
      expect(subject).to eq(1)
    end
  end

  context "webservice account does not exist" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: false),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: true),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true)
      ).call(call_params)
    end

    it "raises the error raised by validate_account_exists" do
      expect { subject }.to raise_error(validate_account_exists_error)
    end
  end

  context "webservice does not exist" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: false),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: true),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true)
      ).call(call_params)
    end

    it "raises the error raised by validate_webservice_exists" do
      expect { subject }.to raise_error(validate_webservice_exists_error)
    end
  end

  context "user does not have update privileges on webservice" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: true),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: false)
      ).call(call_params)
    end

    it "raises the error raised by validate_role_can_access_webservice" do
      expect { subject }.to raise_error(validate_role_can_access_webservice_error)
    end
  end

  context "webservice is not an authenticator" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: false),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true)
      ).call(call_params)
    end

    it "raises the error raised by validate_webservice_is_authenticator" do
      expect { subject }.to raise_error(validate_webservice_is_authenticator_error)
    end
  end
end
