# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGce::UpdateAuthenticatorInput' do

  let(:account) { "my-acct" }
  let(:authenticator_name) { "authn-gce" }
  let(:hostname) { "path/to/host" }
  let(:rooted_hostname) { "host" }

  let(:mocked_verify_and_decode_token) { double("VerifyAndDecodeToken") }
  let(:verify_and_decode_token_error) { "verify and decode token error" }

  before(:each) do
    allow(mocked_verify_and_decode_token).to receive(:call) { |*args|
      JSON.parse(args[0][:token_jwt]).to_hash
    }
  end

  ####################################
  # request mock
  ####################################

  def mock_authenticate_gce_token_request(request_body_data:)
    double('AuthnGceRequest').tap do |request|
      request_body = StringIO.new
      request_body.puts request_body_data
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:authenticate_gce_token_request) do
    mock_authenticate_gce_token_request(request_body_data: "jwt={\"jwt_claim\": \"jwt_claim_value\"}")
  end

  let(:valid_audience) { "conjur/#{account}/#{hostname}" }
  let(:valid_audience_rooted_host) { "conjur/#{account}/#{rooted_hostname}" }
  let(:two_parts_audience) { "two/parts" }
  let(:missing_conjur_prefix_audience) { "not_conjur/#{account}/#{hostname}" }
  let(:incorrect_account_audience) { "conjur/incorrect_account/#{hostname}" }
  let(:admin_audience) { "conjur/#{account}/admin" }

  let(:decoded_token) { double('DecodedToken') }

  def mocked_decoded_token_class(audience)
    double('DecodedToken').tap do |decoded_token_class|
      allow(decoded_token_class).to receive(:new)
                                      .and_return(decoded_token)

      allow(decoded_token).to receive(:audience)
                                .and_return(audience)
    end
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A GCE authenticator" do
    context "that receives an authenticate request" do
      context "with a valid token" do
        context "non-rooted host" do
          subject do
            authenticator_input = Authentication::AuthenticatorInput.new(
              authenticator_name: authenticator_name,
              service_id:         nil,
              account:            account,
              username:           hostname,
              credentials:        request_body(authenticate_gce_token_request),
              client_ip:          '127.0.0.1',
              request:            authenticate_gce_token_request
            )

            ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              decoded_token_class:     mocked_decoded_token_class(valid_audience)
            ).call(
              authenticator_input: authenticator_input
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end

          it "returns the input with the username inside it" do
            expect(subject.username).to eql(hostname)
          end

          it "returns the input with the decoded token as the credentials" do
            expect(subject.credentials).to eql(decoded_token)
          end
        end

        context "rooted host" do
          subject do
            authenticator_input = Authentication::AuthenticatorInput.new(
              authenticator_name: authenticator_name,
              service_id:         nil,
              account:            account,
              username:           hostname,
              credentials:        request_body(authenticate_gce_token_request),
              client_ip:          '127.0.0.1',
              request:            authenticate_gce_token_request
            )

            ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              decoded_token_class:     mocked_decoded_token_class(valid_audience_rooted_host)
            ).call(
              authenticator_input: authenticator_input
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end

          it "returns the input with the username inside it" do
            expect(subject.username).to eql(rooted_hostname)
          end

          it "returns the input with the decoded token as the credentials" do
            expect(subject.credentials).to eql(decoded_token)
          end
        end
      end

      context "with an invalid token" do
        context "that fails to decode" do
          subject do
            authenticator_input = Authentication::AuthenticatorInput.new(
              authenticator_name: authenticator_name,
              service_id:         nil,
              account:            account,
              username:           hostname,
              credentials:        request_body(authenticate_gce_token_request),
              client_ip:          '127.0.0.1',
              request:            authenticate_gce_token_request
            )

            ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
              verify_and_decode_token: mocked_verify_and_decode_token,
              decoded_token_class:     mocked_decoded_token_class(valid_audience)
            ).call(
              authenticator_input: authenticator_input
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

        context "with invalid audience claim" do
          context "invalid length" do
            subject do
              authenticator_input = Authentication::AuthenticatorInput.new(
                authenticator_name: authenticator_name,
                service_id:         nil,
                account:            account,
                username:           hostname,
                credentials:        request_body(authenticate_gce_token_request),
                client_ip:          '127.0.0.1',
                request:            authenticate_gce_token_request
              )

              ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
                verify_and_decode_token: mocked_verify_and_decode_token,
                decoded_token_class:     mocked_decoded_token_class(two_parts_audience)
              ).call(
                authenticator_input: authenticator_input
              )
            end

            it 'raises an InvalidAudience error' do
              expect { subject }.to raise_error(
                Errors::Authentication::AuthnGce::InvalidAudience
              )
            end
          end

          context "missing conjur prefix" do
            subject do
              authenticator_input = Authentication::AuthenticatorInput.new(
                authenticator_name: authenticator_name,
                service_id:         nil,
                account:            account,
                username:           hostname,
                credentials:        request_body(authenticate_gce_token_request),
                client_ip:          '127.0.0.1',
                request:            authenticate_gce_token_request
              )

              ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
                verify_and_decode_token: mocked_verify_and_decode_token,
                decoded_token_class:     mocked_decoded_token_class(missing_conjur_prefix_audience)
              ).call(
                authenticator_input: authenticator_input
              )
            end

            it 'raises an InvalidAudience error' do
              expect { subject }.to raise_error(
                Errors::Authentication::AuthnGce::InvalidAudience
              )
            end
          end

          context "incorrect account" do
            subject do
              authenticator_input = Authentication::AuthenticatorInput.new(
                authenticator_name: authenticator_name,
                service_id:         nil,
                account:            account,
                username:           hostname,
                credentials:        request_body(authenticate_gce_token_request),
                client_ip:          '127.0.0.1',
                request:            authenticate_gce_token_request
              )

              ::Authentication::AuthnGce::UpdateAuthenticatorInput.new(
                verify_and_decode_token: mocked_verify_and_decode_token,
                decoded_token_class:     mocked_decoded_token_class(incorrect_account_audience)
              ).call(
                authenticator_input: authenticator_input
              )
            end

            it 'raises an InvalidAudience error' do
              expect { subject }.to raise_error(
                Errors::Authentication::AuthnGce::InvalidAudience
              )
            end
          end
        end
      end
    end
  end
end
