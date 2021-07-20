# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidators::FetchMandatoryClaims') do

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

  let(:mandatory_claims_resource_name) {Authentication::AuthnJwt::MANDATORY_CLAIMS_RESOURCE_NAME}
  let(:mandatory_claims_valid_secret_value) {'claim1 , claim2'}
  let(:mandatory_claims_valid_parsed_secret_value) {%w[claim1 claim2]}

  let(:mandatory_claims_invalid_secret_value) {'claim1 ,, claim2'}

  def mock_resource_id(resource_name:)
    %r{#{account}:variable:conjur/#{authenticator_name}/#{service_id}/#{resource_name}}
  end

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_resource_exists_values) { double("MockedResource") }
  let(:mocked_resource_not_exists_values) { double("MockedResource") }

  let(:mocked_fetch_secrets_empty_values) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_exist_values) {  double("MockedFetchSecrets") }
  let(:mocked_fetch_secrets_invalid_values) {  double("MockedFetchInvalidSecrets") }
  
  let(:mocked_valid_secrets) {  double("MockedValidSecrets") }
  let(:mocked_invalid_secrets) {  double("MockedInvalidSecrets") }

  let(:required_secret_missing_error) { "required secret missing error" }

  before(:each) do
    allow(mocked_resource_exists_values).to(
      receive(:[]).with(mock_resource_id(resource_name: mandatory_claims_resource_name)).and_return(mocked_resource)
    )

    allow(mocked_resource_not_exists_values).to(
      receive(:[]).and_return(nil)
    )
    
    allow(mocked_fetch_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_fetch_secrets_exist_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: mandatory_claims_resource_name)]).
        and_return(mocked_valid_secrets)
    )

    allow(mocked_valid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: mandatory_claims_resource_name)).
        and_return(mandatory_claims_valid_secret_value)
    )

    allow(mocked_fetch_secrets_invalid_values).to(
      receive(:call).with(resource_ids: [mock_resource_id(resource_name: mandatory_claims_resource_name)]).
        and_return(mocked_invalid_secrets)
    )

    allow(mocked_invalid_secrets).to(
      receive(:[]).with(mock_resource_id(resource_name: mandatory_claims_resource_name)).
        and_return(mandatory_claims_invalid_secret_value)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'mandatory-claims' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidators::FetchMandatoryClaims.new(
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
        ::Authentication::AuthnJwt::RestrictionValidators::FetchMandatoryClaims.new(
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_invalid_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::InvalidMandatoryClaimsFormat)
      end
    end
    
    context "with valid variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidators::FetchMandatoryClaims.new(
          resource_class: mocked_resource_exists_values,
          fetch_required_secrets: mocked_fetch_secrets_exist_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "returns parsed mandatory claims list" do
        expect(subject).to eql(mandatory_claims_valid_parsed_secret_value)
      end
    end
  end

  context "'mandatory-claims' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::RestrictionValidators::FetchMandatoryClaims.new(
        resource_class: mocked_resource_not_exists_values
      ).call(
        authentication_parameters: authentication_parameters
      )
    end

    it "returns an empty mandatory claims list" do
      expect(subject).to eql([])
    end
  end
end
