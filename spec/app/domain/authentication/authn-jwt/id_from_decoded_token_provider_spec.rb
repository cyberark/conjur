# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ConjurIdFromDecodedTokenProvider') do
  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }
  let(:decoded_token) {
    {
      "namespace_id": "1",
      "namespace_path": "root",
      "project_id": "34",
      "project_path": "root/test-proj",
      "user_id": "1",
      "user_login": "cucumber",
      "user_email": "admin@example.com",
      "pipeline_id": "1",
      "job_id": "4",
      "ref": "master",
      "ref_type": "branch",
      "ref_protected": "true",
      "jti": "90c4414b-f7cf-4b98-9a4f-2c29f360e6d0",
      "iss": "ec2-18-157-123-113.eu-central-1.compute.amazonaws.com",
      "iat": 1619352275,
      "nbf": 1619352270,
      "exp": 1619355875,
      "sub": "job_4"
    }
  }

  let(:authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    ), decoded_token)
  }

  let(:non_existing_field_name) { "non existing field name" }
  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "ConjurIdFromDecodedTokenProvider" do
    context "Variable is configured and populated and decoded token containing it" do
      subject do
        id_from_decoded_token_provider = ::Authentication::AuthnJwt::ConjurIdFromDecodedTokenProvider.new(authentication_parameters)
        allow(id_from_decoded_token_provider).to receive(:token_id_field_resource_id).and_return("dummy_secret_id")
        allow(id_from_decoded_token_provider).to receive(:fetch_secret).and_return("user_email")
        id_from_decoded_token_provider.provide_jwt_id
      end

      it "get identity from decoded token successfully" do
        expect(subject).to eql("admin@example.com")
      end

      context "Variable is configured and populated but decoded token not containing it" do
        subject do
          id_from_decoded_token_provider = ::Authentication::AuthnJwt::ConjurIdFromDecodedTokenProvider.new(authentication_parameters)
          allow(id_from_decoded_token_provider).to receive(:token_id_field_resource_id).and_return("dummy_secret_id")
          allow(id_from_decoded_token_provider).to receive(:fetch_secret).and_return(non_existing_field_name)
          id_from_decoded_token_provider
        end

        it "NoSuchFieldInToken error is raised" do
          expect { subject.provide_jwt_id }.to raise_error(Errors::Authentication::AuthnJwt::NoSuchFieldInToken)
        end
      end

      context "Variable is configured but not populated" do
        subject do
          id_from_decoded_token_provider = ::Authentication::AuthnJwt::ConjurIdFromDecodedTokenProvider.new(authentication_parameters)
          allow(id_from_decoded_token_provider).to receive(:token_id_field_resource_id).and_return("dummy_secret_id")
          allow(id_from_decoded_token_provider).to receive(:fetch_secret).and_raise(Errors::Conjur::RequiredSecretMissing)
          id_from_decoded_token_provider
        end

        it "MissingSecretValue error is raised" do
          expect { subject.provide_jwt_id }.to raise_error(Errors::Conjur::MissingSecretValue)
        end
      end
    end
  end
end
