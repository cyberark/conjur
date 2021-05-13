# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::ValidateUriBasedParameters) do
  include_context "security mocks"

  let(:authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: 'authn-dummy',
      service_id: 'my-service-id',
      account: 'my-account',
      username: nil,
      credentials: nil,
      client_ip: '127.0.0.1',
      request: { }
    )
  }

  let(:enabled_authenticators) { 'csv,example' }

  context "A ValidateUriBasedParameters invocation" do
    context "that passes all validations" do
      subject do
        Authentication::AuthnJwt::ValidateUriBasedParameters.new(
          validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
          validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true)
        ).call(
          authenticator_input: authenticator_input,
          enabled_authenticators: enabled_authenticators
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context "that does not pass account validation" do
      subject do
        Authentication::AuthnJwt::ValidateUriBasedParameters.new(
          validate_account_exists: mock_validate_account_exists(validation_succeeded: false),
          validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: true)
        ).call(
          authenticator_input: authenticator_input,
          enabled_authenticators: enabled_authenticators
        )
      end

      it 'raises an error' do
        expect { subject }.to(
          raise_error(
            validate_account_exists_error
          )
        )
      end
    end

    context "that does not pass webservice validation" do
      subject do
        Authentication::AuthnJwt::ValidateUriBasedParameters.new(
          validate_account_exists: mock_validate_account_exists(validation_succeeded: true),
          validate_webservice_is_whitelisted: mock_validate_webservice_is_whitelisted(validation_succeeded: false)
        ).call(
          authenticator_input: authenticator_input,
          enabled_authenticators: enabled_authenticators
        )
      end

      it 'raises an error' do
        expect { subject }.to(
          raise_error(
            validate_webservice_is_whitelisted_error
          )
        )
      end
    end
  end
end
