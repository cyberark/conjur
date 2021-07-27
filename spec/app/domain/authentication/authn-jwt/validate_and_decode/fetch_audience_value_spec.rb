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

  let(:authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: authenticator_input,
      jwt_token: nil
    )
  }

  let(:audience_resource_name) {Authentication::AuthnJwt::AUDIENCE_RESOURCE_NAME}
  let(:audience_valid_secret_value_string) {'valid-string-value'}
  let(:audience_valid_secret_value_uri) {'https://host.com/path'}
  let(:audience_invalid_secret_value_uri) {':scheme::something::else'}

  def mock_resource_id(resource_name:)
    %r{#{account}:variable:conjur/#{authenticator_name}/#{service_id}/#{resource_name}}
  end

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_resource_exists_values) { double("MockedResource") }
  let(:mocked_resource_not_exists_values) { double("MockedResource") }

  let(:mocked_fetch_secrets_empty_values) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_exist_values_string) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_exist_values_uri) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_invalid_values) {  double("MockedFetchInvalidSecrets") }
  
  let(:mocked_valid_secrets_string) {  double("MockedValidSecrets") }
  let(:mocked_valid_secrets_uri) {  double("MockedValidSecrets") }
  let(:mocked_invalid_secrets) {  double("MockedInvalidSecrets") }

  let(:required_secret_missing_error) { "required secret missing error" }

  before(:each) do
    allow(mocked_resource_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: audience_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_not_exists_values).to(
      receive(:[]).and_return(nil)
    )
    
    allow(mocked_fetch_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_fetch_secrets_exist_values_string).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: audience_resource_name)]).
        and_return(mocked_valid_secrets_string)
    )

    allow(mocked_valid_secrets_string).to(
      receive(:[]).with(mock_resource_id(resource_name: audience_resource_name)).
        and_return(audience_valid_secret_value_string)
    )

    allow(mocked_fetch_secrets_exist_values_uri).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: audience_resource_name)]).
        and_return(mocked_valid_secrets_uri)
    )

    allow(mocked_valid_secrets_uri).to(
      receive(:[]).with(mock_resource_id(resource_name: audience_resource_name)).
        and_return(audience_valid_secret_value_uri)
    )

    allow(mocked_fetch_secrets_invalid_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: audience_resource_name)]).
        and_return(mocked_invalid_secrets)
    )

    allow(mocked_invalid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: audience_resource_name)).
        and_return(audience_invalid_secret_value_uri)
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
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_empty_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_secret_missing_error)
      end
    end

    context "with invalid variable value" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_invalid_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::AudienceValueIsNotURI,
                                /.*CONJ00116E.*URI::InvalidURIError.*/
                              )
      end
    end
    
    context "with valid variable value string" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_exist_values_string
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "returns the value" do
        expect(subject).to eql(audience_valid_secret_value_string)
      end
    end

    context "with valid variable value uri" do
      subject do
        ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_exist_values_uri
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "returns the value" do
        expect(subject).to eql(audience_valid_secret_value_uri)
      end
    end
  end

  context "'audience' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new(
        resource_class: mocked_resource_not_exists_values
      ).call(
        authentication_parameters: authentication_parameters
      )
    end

    it "returns an empty string" do
      expect(subject).to eql("")
    end
  end
end
