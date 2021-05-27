# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials) do

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

  let(:jwt_token) do
    "#{header}.#{body}.#{signature}"
  end

  let(:credentials) do
    "jwt=#{jwt_token}"
  end

  context "Request body" do
    context "that contains a valid jwt token parameter" do
      subject do
        Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new().call(
          credentials: credentials
        )
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'authentication parameters contain jwt token' do
        expect(subject).to eq(jwt_token)
      end
    end
  end
end
