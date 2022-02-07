# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnAzure::Authenticator') do
  include_context "base64url"
  include_context "security mocks"
  include_context "fetch secrets", %w[provider-uri]

  let(:account) { "my-acct" }
  let(:authenticator_name) { "authn-azure" }
  let(:service) { "my-service" }

  let(:mocked_verify_and_decode_token) { double("VerifyAndDecodeAzureToken") }
  let(:mocked_validate_resource_restrictions) { double("ValidateResourceRestrictions") }
  let(:mocked_authentication_request_class) { double("AuthenticationRequest") }
  let(:mocked_authentication_request) { double("AuthenticationRequest") }

  let(:verify_and_decode_token_error) { "verify and decode token error" }

  before(:each) do
    allow(mocked_verify_and_decode_token).to receive(:call) { |*args|
      JSON.parse(base64_url_decode(args[0][:token_jwt].split('.')[1])).to_hash
    }

    allow(mocked_validate_resource_restrictions).to receive(:call).and_return(true)
    allow(mocked_authentication_request_class).to receive(:new).and_return(mocked_authentication_request)
  end

  ####################################
  # request mock
  ####################################

  def mock_authenticate_azure_token_request(request_body_data:)
    double('AuthnAzureRequest').tap do |request|
      request_body = StringIO.new
      request_body.puts(request_body_data)
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:authenticate_azure_token_request) do
    mock_authenticate_azure_token_request(
      request_body_data:
        "jwt=aa.#{base64_url_encode("{\"xms_mirid\": \"some_xms_mirid_value\", \"oid\": \"some_oid_value\"}")}.cc")
  end

  let(:authenticate_azure_token_request_missing_xms_mirid_field) do
    mock_authenticate_azure_token_request(
      request_body_data:
        "jwt=aa.#{base64_url_encode("{\"oid\": \"some_oid_value\"}")}.cc")
  end

  let(:authenticate_azure_token_request_missing_oid_field) do
    mock_authenticate_azure_token_request(
      request_body_data:
        "jwt=aa.#{base64_url_encode("{\"xms_mirid\": \"some_xms_mirid_value\"}")}.cc")
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An Azure authenticator" do
    context "that receives an authenticate request" do
      context "with a valid azure token" do
        context "with valid resource restrictions" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: authenticator_name,
              service_id: service,
              account: account,
              username: 'my-user',
              credentials: request_body(authenticate_azure_token_request),
              client_ip: '127.0.0.1',
              request: authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              validate_resource_restrictions: mocked_validate_resource_restrictions,
              authentication_request_class: mocked_authentication_request_class
            ).call(
              authenticator_input: input_
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
            expect(subject).to eq(true)
          end

          it_behaves_like "it fails when variable is missing or has no value", "provider-uri"
        end

        context "with invalid resource restrictions" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id: 'my-service',
              account: 'my-acct',
              username: nil,
              credentials: request_body(authenticate_azure_token_request),
              client_ip: '127.0.0.1',
              request: authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              validate_resource_restrictions: mocked_validate_resource_restrictions
            ).call(
              authenticator_input: input_
            )
          end

          it 'raises the error raised by mocked_validate_resource_restrictions' do
            allow(mocked_validate_resource_restrictions).to receive(:call)
              .and_raise('FAKE_VALIDATE_RESOURCE_RESTRICTIONS_ERROR')

            expect { subject }.to raise_error(
              /FAKE_VALIDATE_RESOURCE_RESTRICTIONS_ERROR/
            )
          end
        end
      end

      context "with an invalid azure token" do
        context "that fails token verification" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-azure',
              service_id: 'my-service',
              account: 'my-acct',
              username: nil,
              credentials: request_body(authenticate_azure_token_request),
              client_ip: '127.0.0.1',
              request: authenticate_azure_token_request
            )

            ::Authentication::AuthnAzure::Authenticator.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              validate_resource_restrictions: mocked_validate_resource_restrictions
            ).call(
              authenticator_input: input_
            )
          end

          it 'raises the error raised by mocked_verify_and_decode_token' do
            allow(mocked_verify_and_decode_token).to receive(:call)
              .and_raise(verify_and_decode_token_error)

            expect { subject }.to raise_error(
              verify_and_decode_token_error
            )
          end
        end
      end
    end
  end
end
