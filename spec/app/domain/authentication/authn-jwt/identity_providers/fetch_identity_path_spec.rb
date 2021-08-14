# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath') do

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

  let(:authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: authenticator_input,
      jwt_token: nil
    )
  }

  let(:identity_path_secret_value) {
    {
      "identity-path" => "apps/sub-apps"
    }
  }
  let(:mocked_authenticator_secret_not_exists) { double("Mocked authenticator secret not exists")  }
  let(:mocked_authenticator_secret_exists) { double("Mocked authenticator secret exists") }
  let(:mocked_fetch_authenticator_secrets_exist_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:required_secret_missing_error) { "required secret missing error" }

  before(:each) do
    allow(mocked_authenticator_secret_exists).to(
      receive(:call).and_return(true)
    )

    allow(mocked_authenticator_secret_not_exists).to(
      receive(:call).and_return(false)
    )

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).and_return(
        {
          "identity-path" => identity_path_secret_value
        }
      )
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'identity-path' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new(
        check_authenticator_secret_exists: mocked_authenticator_secret_not_exists
      ).call(
        authentication_parameters: authentication_parameters
      )
    end

    it "returns identity path value" do
      expect(subject).to eql(::Authentication::AuthnJwt::IDENTITY_PATH_DEFAULT_VALUE)
    end
  end

  context "'identity-path' variable is configured in authenticator policy" do
    context "with valid value" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "returns identity path value" do
        expect(subject).to eql(identity_path_secret_value)
      end
    end

    context "with empty value" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_secret_missing_error)
      end
    end
  end
end
