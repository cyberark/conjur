# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::Authenticator' do

  include_context "fetch secrets", %w(provider-uri)

  let(:account) {"my-acct"}
  let(:authenticator_name) {"authn-azure"}
  let(:service) {"my-service"}

  let(:mocked_verify_and_decode_token) {double("VerifyAndDecodeAzureToken")}
  let(:mocked_validate_application_identity) {double("ValidateApplicationIdentity")}

  before(:each) do
    allow(mocked_verify_and_decode_token).to receive(:call) {|*args|
      JSON.parse(args[0][:token_jwt]).to_hash
    }

    allow(mocked_validate_application_identity).to receive(:call).and_return(true)
  end

  ####################################
  # request mock
  ####################################

  def mock_authenticate_azure_token_request(request_body_data:)
    double('AuthnAzureRequest').tap do |request|
      request_body = StringIO.new
      request_body.puts request_body_data
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:authenticate_azure_token_request) do
    mock_authenticate_azure_token_request(request_body_data: "jwt={\"xms_mirid\": \"some_xms_mirid_value\", \"oid\": \"some_oid_value\"}")
  end

  let(:authenticate_azure_token_request_missing_xms_mirid_field) do
    mock_authenticate_azure_token_request(request_body_data: "jwt={\"oid\": \"some_oid_value\"}")
  end

  let(:authenticate_azure_token_request_missing_oid_field) do
    mock_authenticate_azure_token_request(request_body_data: "jwt={\"xms_mirid\": \"some_xms_mirid_value\"}")
  end

  let(:authenticate_azure_token_request_missing_jwt_field) do
    mock_authenticate_azure_token_request(request_body_data: "some_key=some_value")
  end

  let(:authenticate_azure_token_request_empty_jwt_field) do
    mock_authenticate_azure_token_request(request_body_data: "jwt=")
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An Azure authenticator" do
    context "that receives an authenticate request" do
      context "with a valid azure token" do
        context "with a valid application identity" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: authenticator_name,
              service_id:         service,
              account:            account,
              username:           'my-user',
              credentials:        request_body(authenticate_azure_token_request),
              origin:             '127.0.0.1',
              request:            authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token:       mocked_verify_and_decode_token,
              validate_application_identity: mocked_validate_application_identity
            ).call(
              authenticator_input: input_
            )
          end

          it "does not raise an error" do
            expect {subject}.to_not raise_error
            expect(subject).to eq(true)
          end

          it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
        end

        context "with an invalid application identity" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id:         'my-service',
              account:            'my-acct',
              username:           nil,
              credentials:        request_body(authenticate_azure_token_request),
              origin:             '127.0.0.1',
              request:            authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token:       mocked_verify_and_decode_token,
              validate_application_identity: mocked_validate_application_identity
            ).call(
              authenticator_input: input_
            )
          end

          it 'raises the error raised by mocked_validate_application_identity' do
            allow(mocked_validate_application_identity).to receive(:call)
                                                             .and_raise('FAKE_VALIDATE_APPLICATION_IDENTITY_ERROR')

            expect {subject}.to raise_error(
                                  /FAKE_VALIDATE_APPLICATION_IDENTITY_ERROR/
                                )
          end
        end
      end

      context "with an invalid azure token" do
        context "that fails token verification" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id:         'my-service',
              account:            'my-acct',
              username:           nil,
              credentials:        request_body(authenticate_azure_token_request),
              origin:             '127.0.0.1',
              request:            authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token:       mocked_verify_and_decode_token,
              validate_application_identity: mocked_validate_application_identity
            ).call(
              authenticator_input: input_
            )
          end

          it 'raises the error raised by mocked_verify_and_decode_token' do
            allow(mocked_verify_and_decode_token).to receive(:call)
                                                       .and_raise('FAKE_VERIFY_AND_DECODE_ERROR')

            expect {subject}.to raise_error(
                                  /FAKE_VERIFY_AND_DECODE_ERROR/
                                )
          end
        end

        context "that is missing the xms_mirid field" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id:         'my-service',
              account:            'my-acct',
              username:           nil,
              credentials:        request_body(authenticate_azure_token_request_missing_xms_mirid_field),
              origin:             '127.0.0.1',
              request:            authenticate_azure_token_request_missing_xms_mirid_field
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token:       mocked_verify_and_decode_token,
              validate_application_identity: mocked_validate_application_identity
            ).call(
              authenticator_input: input_
            )
          end

          it "raises a TokenFieldNotFoundOrEmpty error" do
            expect {subject}.to raise_error(::Errors::Authentication::AuthnAzure::TokenFieldNotFoundOrEmpty)
          end
        end

        context "that is missing the oid field" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id:         'my-service',
              account:            'my-acct',
              username:           nil,
              credentials:        request_body(authenticate_azure_token_request_missing_oid_field),
              origin:             '127.0.0.1',
              request:            authenticate_azure_token_request_missing_oid_field
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token:       mocked_verify_and_decode_token,
              validate_application_identity: mocked_validate_application_identity
            ).call(
              authenticator_input: input_
            )
          end

          it "raises a TokenFieldNotFoundOrEmpty error" do
            expect {subject}.to raise_error(::Errors::Authentication::AuthnAzure::TokenFieldNotFoundOrEmpty)
          end
        end
      end

      context "with no jwt field in the request" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-azure',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_azure_token_request_missing_jwt_field),
            origin:             '127.0.0.1',
            request:            authenticate_azure_token_request_missing_jwt_field
          )

          ::Authentication::AuthnAzure::Authenticator.new(
            verify_and_decode_token:       mocked_verify_and_decode_token,
            validate_application_identity: mocked_validate_application_identity
          ).call(
            authenticator_input: input_
          )
        end

        it "raises a MissingRequestParam error" do
          expect {subject}.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end

      context "with an empty jwt field in the request" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-azure',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_azure_token_request_empty_jwt_field),
            origin:             '127.0.0.1',
            request:            authenticate_azure_token_request_empty_jwt_field
          )

          ::Authentication::AuthnAzure::Authenticator.new(
            verify_and_decode_token:       mocked_verify_and_decode_token,
            validate_application_identity: mocked_validate_application_identity
          ).call(
            authenticator_input: input_
          )
        end

        it "raises a MissingRequestParam error" do
          expect {subject}.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
    end
  end
end
