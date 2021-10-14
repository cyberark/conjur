# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases') do

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

  let(:jwt_authenticator_input) {
    Authentication::AuthnJwt::JWTAuthenticatorInput.new(
      authenticator_input: authenticator_input,
      decoded_token: nil
    )
  }

  let(:claim_aliases_resource_name) {Authentication::AuthnJwt::CLAIM_ALIASES_RESOURCE_NAME}
  let(:claim_aliases_valid_secret_value) {'name1:name2,name2:name3,name3:name1'}
  let(:claim_aliases_valid_parsed_secret_value) {{"name1"=>"name2", "name2"=>"name3", "name3"=>"name1"}}

  let(:claim_aliases_invalid_secret_value) {'name1:name2 ,, name3:name1'}

  let(:mocked_resource) { double("MockedResource") }
  let(:mocked_authenticator_secret_not_exists) { double("Mocked authenticator secret not exists")  }
  let(:mocked_authenticator_secret_exists) { double("Mocked authenticator secret exists") }

  let(:mocked_fetch_authenticator_secrets_valid_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_invalid_values)  {  double("MochedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MochedFetchAuthenticatorSecrets") }

  let(:mocked_valid_secrets) {
    {
      claim_aliases_resource_name => claim_aliases_valid_secret_value
    }
  }

  let(:mocked_invalid_secrets) {
    {
      claim_aliases_resource_name => claim_aliases_invalid_secret_value
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

  context "'claim-aliases' variable is configured in authenticator policy" do
    context "with empty variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_empty_values
        ).call(
          jwt_authenticator_input: jwt_authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_secret_missing_error)
      end
    end

    context "with invalid variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_invalid_values
        ).call(
          jwt_authenticator_input: jwt_authenticator_input
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ClaimAliasesBlankOrEmpty)
      end
    end
    
    context "with valid variable value" do
      subject do
        ::Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new(
          check_authenticator_secret_exists: mocked_authenticator_secret_exists,
          fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_valid_values
        ).call(
          jwt_authenticator_input: jwt_authenticator_input
        )
      end

      it "returns parsed claim aliases hashtable" do
        expect(subject).to eql(claim_aliases_valid_parsed_secret_value)
      end
    end
  end

  context "'claim-aliases' variable is not configured in authenticator policy" do
    subject do
      ::Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new(
        check_authenticator_secret_exists: mocked_authenticator_secret_not_exists
      ).call(
        jwt_authenticator_input: jwt_authenticator_input
      )
    end

    it "returns an empty claim aliases hashtable" do
      expect(subject).to eql({})
    end
  end
end
