# frozen_string_literal: true

require 'spec_helper'
require 'support/security_specs_helper'
require 'support/fetch_secrets_helper'
require 'json'

RSpec.describe Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken do

  include_context "fetch secrets", %w(provider-uri id-token-user-property)
  include_context "security mocks"
  include_context "oidc setup"

  let (:mocked_decode_and_verify_id_token) do
    double("MockIdTokenDecodeAndVerify")
  end

  before(:each) do
    allow(mocked_decode_and_verify_id_token).to(
      receive(:call) do |*args|
        token = args[0][:token_jwt]
        JSON.parse(token).to_hash
      end
    )
  end

  ####################################
  # request mock
  ####################################

  def mock_authenticate_oidc_request(request_body_data:)
    double('AuthnOidcRequest').tap do |request|
      request_body = StringIO.new
      request_body.puts request_body_data
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:authenticate_id_token_request) do
    mock_authenticate_oidc_request(request_body_data: "id_token={\"id_token_username_field\": \"alice\"}")
  end

  let(:authenticate_id_token_request_missing_id_token_username_field) do
    mock_authenticate_oidc_request(request_body_data: "id_token={}")
  end

  let(:authenticate_id_token_request_empty_id_token_username_field) do
    mock_authenticate_oidc_request(request_body_data: "id_token={\"id_token_username_field\": \"\"}")
  end

  let(:authenticate_id_token_request_missing_id_token_field) do
    mock_authenticate_oidc_request(request_body_data: "some_key=some_value")
  end

  let(:authenticate_id_token_request_empty_id_token_field) do
    mock_authenticate_oidc_request(request_body_data: "id_token=")
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "An oidc authenticator" do
    context "that receives authenticate id token request" do
      before(:each) do
        allow(Resource).to(
          receive(:[]).with(
            /#{account}:variable:conjur\/authn-oidc\/#{service}\/id-token-user-property/
          ).and_return(mocked_id_token_resource)
        )
      end

      context "with valid id token" do
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_id_token_request),
            client_ip:          '127.0.0.1',
            request:            authenticate_id_token_request
          )

          ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
            verify_and_decode_token: mocked_decode_and_verify_id_token,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            authenticator_input: input_
          )
        end

        it "returns the input with the username inside it" do
          expect(subject.username).to eql("alice")
        end

        it_behaves_like(
          "it fails when variable is missing or has no value",
          "provider-uri"
        )
        it_behaves_like(
          "it fails when variable is missing or has no value",
          "id-token-user-property"
        )

        context "a non-existing account" do
          subject do
            input_ = Authentication::AuthenticatorInput.new(
              authenticator_name: 'authn-oidc',
              service_id:         'my-service',
              account:            'my-acct',
              username:           nil,
              credentials:        request_body(authenticate_id_token_request),
              client_ip:          '127.0.0.1',
              request:            authenticate_id_token_request
            )

            ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
              verify_and_decode_token: mocked_decode_and_verify_id_token,
              validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
            ).call(
              authenticator_input: input_
            )
          end

          it "raises the error raised by validate_account_exists" do
            expect { subject }.to raise_error(validate_account_exists_error)
          end
        end
      end

      context "with no id token username field in id token" do
        let(:audit_success) { false }
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_id_token_request_missing_id_token_username_field),
            client_ip:          '127.0.0.1',
            request:            authenticate_id_token_request_missing_id_token_username_field
          )

          ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
            verify_and_decode_token: mocked_decode_and_verify_id_token,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to(
            raise_error(
              ::Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
            )
          )
        end
      end

      context "with empty id token username value in id token" do
        let(:audit_success) { false }
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_id_token_request_empty_id_token_username_field),
            client_ip:          '127.0.0.1',
            request:            authenticate_id_token_request_empty_id_token_username_field
          )

          ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
            verify_and_decode_token: mocked_decode_and_verify_id_token,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            authenticator_input: input_
          )
        end

        it "raises an error" do
          expect { subject }.to(
            raise_error(
              ::Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
            )
          )
        end
      end

      context "with no id_token field in the request" do
        let(:audit_success) { false }

        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_id_token_request_missing_id_token_field),
            client_ip:          '127.0.0.1',
            request:            authenticate_id_token_request_missing_id_token_field
          )

          ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
            verify_and_decode_token: mocked_decode_and_verify_id_token,
          validate_account_exists:   mock_validate_account_exists(validation_succeeded: true)

          ).call(
            authenticator_input: input_
          )
        end

        it "raises a MissingRequestParam error" do
          expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end

      context "with an empty id_token field in the request" do
        let(:audit_success) { false }
        subject do
          input_ = Authentication::AuthenticatorInput.new(
            authenticator_name: 'authn-oidc',
            service_id:         'my-service',
            account:            'my-acct',
            username:           nil,
            credentials:        request_body(authenticate_id_token_request_empty_id_token_field),
            client_ip:          '127.0.0.1',
            request:            authenticate_id_token_request_empty_id_token_field
          )

          ::Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new(
            verify_and_decode_token: mocked_decode_and_verify_id_token,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            authenticator_input: input_
          )
        end

        it "raises a MissingRequestParam error" do
          expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
        end
      end
    end
  end
end
