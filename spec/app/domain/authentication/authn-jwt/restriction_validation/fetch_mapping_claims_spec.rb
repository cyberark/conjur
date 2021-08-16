# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims') do

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

  let(:mapping_claims_resource_name) {Authentication::AuthnJwt::MAPPING_CLAIMS_RESOURCE_NAME}
  let(:mapping_claims_valid_secret_value) {'name1:name2,name2:name3,name3:name1'}
  let(:mapping_claims_valid_parsed_secret_value) {{"name1"=>"name2", "name2"=>"name3", "name3"=>"name1"}}

  let(:mapping_claims_invalid_secret_value) {'name1:name2 ,, name3:name1'}

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_authenticator_secret_not_exists) { double("Mocked authenticator secret not exists")  }
  let(:mocked_authenticator_secret_exists) { double("Mocked authenticator secret exists") }

  let(:mocked_fetch_authenticator_secrets_valid_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_invalid_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MochedFetchAuthenticatorSecrets") }

  let(:mocked_valid_secrets) {
    {
      mapping_claims_resource_name => mapping_claims_valid_secret_value
    }
  }

  let(:mocked_invalid_secrets) {
    {
      mapping_claims_resource_name => mapping_claims_invalid_secret_value
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

    allow(mocked_fetch_authenticator_secrets_invalid_values).to(
      receive(:call).and_return(mocked_invalid_secrets)
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'mapping-claims' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims.new(
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

    context "with invalid variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_invalid_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MappingClaimsBlankOrEmpty)
      end
    end
    
    context "with valid variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_valid_values
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it "returns parsed mapping claims hashtable" do
        expect(subject).to eql(mapping_claims_valid_parsed_secret_value)
      end
    end
  end

  context "'mapping-claims' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims.new(
        check_authenticator_secret_exists: mocked_authenticator_secret_not_exists
      ).call(
        authentication_parameters: authentication_parameters
      )
    end

    it "returns an empty mapping claims hashtable" do
      expect(subject).to eql({})
    end
  end
end
