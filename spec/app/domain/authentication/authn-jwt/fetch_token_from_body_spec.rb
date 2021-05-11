# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::FetchTokenFromBody) do

  def mock_authenticate_token_request(request_body_data:)
    double('JwtRequest').tap do |request|
      request_body = StringIO.new
      request_body.print request_body_data
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:header) do
    'eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9'
  end

  let(:body) do
    'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0'
  end

  let(:signature) do
    'hZnl5amPk_I3tb4O-Otci_5XZdVWhPlFyVRvcqSwnDo_srcysDvhhKOD01DigPK1lJvTSTolyUgKGtpLqMfRDXQlekRsF4XhA'\
'jYZTmcynf-C-6wO5EI4wYewLNKFGGJzHAknMgotJFjDi_NCVSjHsW3a10nTao1lB82FRS305T226Q0VqNVJVWhE4G0JQvi2TssRtCxYTqzXVt22iDKkXe'\
'ZJARZ1paXHGV5Kd1CljcZtkNZYIGcwnj65gvuCwohbkIxAnhZMJXCLaVvHqv9l-AAUV7esZvkQR1IpwBAiDQJh4qxPjFGylyXrHMqh5NlT_pWL2ZoULWT'\
'g_TJjMO9TuQ'
  end

  let(:header_body) do
    "#{prefix}#{header}.#{body}"
  end

  let(:header_body_period) do
    "#{prefix}#{header}.#{body}."
  end

  let(:header_signature) do
    "#{prefix}#{header}..#{signature}"
  end

  let(:jwt_token) do
    "#{header}.#{body}.#{signature}"
  end

  let(:credentials) do
    "jwt=#{jwt_token}"
  end

  let(:authenticate_token_request) do
    mock_authenticate_token_request(request_body_data: credentials)
  end

  let(:authentication_parameters) do
    Authentication::AuthnJwt::AuthenticationParameters.new(
      Authentication::AuthenticatorInput.new(
      authenticator_name: "authn-dummy",
      service_id: "my_service_id",
      account: "my_account",
      username: "dummy_identity",
      client_ip: "dummy",
      credentials: nil,
      request: authenticate_token_request
    ))
  end

  context "Request body" do
    context "that contains a valid jwt token parameter" do
      subject do
        auth_params = authentication_parameters
        Authentication::AuthnJwt::FetchTokenFromBody.new().call(
          authentication_parameters: auth_params
        )
        auth_params
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'authentication parameters contain credentials' do
        expect(subject.credentials).to eq(credentials)
      end

      it 'authentication parameters contain jwt token' do
        expect(subject.jwt_token).to eq(jwt_token)
      end
    end
  end
end
