require 'spec_helper'

RSpec.describe(Authentication::UpdateAuthenticatorConfig) do
  include_context "security mocks"

  let(:authenticator_name) { "authn-test" }
  let(:service_id) { "test-service" }

  let(:mock_model) { double(::AuthenticatorConfig) }

  before do
    allow(mock_model)
      .to receive_message_chain(:find_or_create, :update)
      .and_return(1)
  end

  def mock_update_config_input
    double('update_config_input').tap do |update_config_input|
      allow(update_config_input).to receive(:authenticator_name)
                               .and_return(authenticator_name)

      allow(update_config_input).to receive(:account)
                               .and_return(test_account)

      allow(update_config_input).to receive(:service_id)
                               .and_return(service_id)

      allow(update_config_input).to receive(:username)
                               .and_return(test_user_id)

      allow(update_config_input).to receive(:enabled)
                               .and_return(true)
    end
  end

  context "webservice resource exists and the current user has correct permissions" do
    let(:subject) do
      Authentication::UpdateAuthenticatorConfig.new(
        authenticator_config_class: mock_model,
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_webservice_is_authenticator: mock_validate_webservice_is_authenticator(validation_succeeded: true),
        validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true)
      ).call(update_config_input: mock_update_config_input)
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
      ).call(update_config_input: mock_update_config_input)
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
      ).call(update_config_input: mock_update_config_input)
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
      ).call(update_config_input: mock_update_config_input)
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
      ).call(update_config_input: mock_update_config_input)
    end

    it "raises the error raised by validate_webservice_is_authenticator" do
      expect { subject }.to raise_error(validate_webservice_is_authenticator_error)
    end
  end
end
