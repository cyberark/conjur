# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::ValidateInput) do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    ))
  }

  let(:validate_request_body) { double("ValidateRequestBody") }

  before(:each) do
    allow(Authentication::AuthnJwt::ValidateRequestBody)
      .to receive(:new)
            .and_return(validate_request_body)
    allow(validate_request_body)
      .to receive(:call)
            .and_return(true)
  end

  context "A ValidateInput invocation" do
    context "that validates JTW specific input parameters" do
      subject do
        Authentication::AuthnJwt::ValidateInput.new(
          validate_request_body: validate_request_body
        ).call(
          authentication_parameters: authentication_parameters
        )
      end

      it 'when body contains a valid JWT token' do
        expect { subject }.not_to raise_error
      end

      it 'when body contains an in-valid JWT token' do
        allow(validate_request_body).to receive(:call)
                                                   .and_raise('FAKE_REQUEST_BODY_ERROR')
        expect { subject }.to(
          raise_error(
            /FAKE_REQUEST_BODY_ERROR/
          )
        )
      end
    end

  end
end
