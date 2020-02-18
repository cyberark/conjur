# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::Authenticator' do

  include_context "fetch secrets"

  let(:azure_authenticator_name) { "authn-azure-test" }

  let(:azure_authenticator_secrets) do
    {
      "provider-uri" => "test-uri"
    }
  end

  let (:mocked_verify_and_decode_token) { double("VerifyAndDecodeAzureToken") }

  before(:each) do
    allow(mocked_verify_and_decode_token).to receive(:call) { |*args|
      JSON.parse(args[0][:token_jwt]).to_hash
    }
  end

  ####################################
  # request mock
  ####################################

  let (:authenticate_azure_token_request) do
    request_body = StringIO.new
    request_body.puts "jwt={\"xms_mirid\": \"some_xms_mirid_value\", \"oid\": \"some_oid_value\"}"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  let (:authenticate_azure_token_request_missing_azure_token_field) do
    request_body = StringIO.new
    request_body.puts "some_key=some_value"
    request_body.rewind

    double('Request').tap do |request|
      allow(request).to receive(:body).and_return(request_body)
    end
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An Azure authenticator" do
    context "that receives an authenticate request" do
      context "with a valid azure token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-azure',
            service_id:         'my-service',
            account:            'my-acct',
            username:           'my-user',
            credentials:        authenticate_azure_token_request.body.read,
            origin:             '127.0.0.1',
            request:            authenticate_azure_token_request
          )

          ::Authentication::AuthnAzure::Authenticator.new(
            fetch_authenticator_secrets: mock_fetch_secrets(
                                           is_successful: true,
                                           fetched_secrets: azure_authenticator_secrets
                                         ),
            verify_and_decode_token: mocked_verify_and_decode_token,
            ).call(
            authenticator_input: input_
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
          expect(subject).to eq(true)
        end
      end

      context "with no azure_token field in the request" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-azure',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        authenticate_azure_token_request_missing_azure_token_field.body.read,
            origin:             '127.0.0.1',
            request:            authenticate_azure_token_request_missing_azure_token_field
          )

          ::Authentication::AuthnAzure::Authenticator.new(
            fetch_authenticator_secrets: mock_fetch_secrets(
                                           is_successful: true,
                                           fetched_secrets: azure_authenticator_secrets
                                         ),
            verify_and_decode_token: mocked_verify_and_decode_token,
            ).call(
            authenticator_input: input_
          )
        end

        it "raises a MissingRequestParam error" do
          expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end

      context "Required variables do not exist or does not have value" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-azure',
            service_id:         'my-service',
            account:            'my-acct',
            username:           'my-user',
            credentials:        authenticate_azure_token_request.body.read,
            origin:             '127.0.0.1',
            request:            authenticate_azure_token_request
          )

          ::Authentication::AuthnAzure::Authenticator.new(
            fetch_authenticator_secrets: mock_fetch_secrets(
                                           is_successful: false,
                                           fetched_secrets: nil
                                         ),
            verify_and_decode_token: mocked_verify_and_decode_token,
            ).call(
            authenticator_input: input_
          )
        end

        it "raises the error raised by fetch_authenticator_secrets" do
          expect { subject }.to raise_error(test_fetch_secrets_error)
        end
      end
    end
  end
end
