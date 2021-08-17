# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    )
  }

  let(:audience_resource_name) {Authentication::AuthnJwt::AUDIENCE_RESOURCE_NAME}
  let(:audience_valid_secret_value) {'valid-string-value'}

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_authenticator_secret_exists) { double("MockedResource") }
  let(:mocked_authenticator_secret_not_exists) { double("MockedResource") }

  let(:mocked_fetch_authenticator_secrets_valid_values) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values) {  double("MockedFetchSecrets") }

  let(:mocked_valid_secrets) {
    {
      audience_resource_name => 'valid-string-value'
    }
  }

  let(:required_secret_missing_error) { "required secret missing error" }

  before(:each) do
    allow(mocked_authenticator_secret_exists).to(
      receive(:call).and_return(true)
    )

    allow(mocked_authenticator_secret_not_exists).to(
      receive(:call).and_return(false)
    )

    allow(mocked_fetch_authenticator_secrets_valid_values).to(
      receive(:call).and_return(mocked_valid_secrets)
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'audience' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_values
        ).call(
          authenticator_input: authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_secret_missing_error)
      end
    end

    context "with valid variable value string" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_valid_values
        ).call(
          authenticator_input: authenticator_input
        )
      end

      it "returns the value" do
        expect(subject).to eql(audience_valid_secret_value)
      end
    end
  end

  context "'audience' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
        check_authenticator_secret_exists: mocked_authenticator_secret_not_exists
      ).call(
        authenticator_input: authenticator_input
      )
    end

    it "returns an empty string" do
      expect(subject).to eql("")
    end
  end
end
