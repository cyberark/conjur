# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::Jwt::DecodedCredentials') do

  let(:prefix) do
    'jwt='
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

  let(:valid_token) do
    "#{header}.#{body}.#{signature}"
  end

  let(:authenticate_token_request) do
    "#{prefix}#{valid_token}"
  end

  let(:control_character_token_request) do
    "#{prefix}#{header}.#{body}\b.#{signature}"
  end

  let(:new_line_token_request) do
    "#{prefix}#{header}.#{body}.#{signature}\n"
  end

  let(:authenticate_token_request_missing_jwt_parameter) do
    "some_key=some_value"
  end

  let(:empty_authenticate_token_request) do
    ""
  end

  let(:multiple_parameters_request) do
    "#{authenticate_token_request_missing_jwt_parameter}&#{authenticate_token_request}"
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Credentials" do
    context "with a jwt token as a single parameter" do
      subject(:decoded_credentials) do
        ::Authentication::Jwt::DecodedCredentials.new(authenticate_token_request)
      end

      it "does not raise an error" do
        expect { decoded_credentials }.to_not raise_error
      end

      it "parses the jwt claim expectedly" do
        expect(decoded_credentials.jwt).to eq(valid_token)
      end
    end

    context "with a jwt token and additional parameters" do
      subject(:decoded_credentials) do
        ::Authentication::Jwt::DecodedCredentials.new(authenticate_token_request)
      end

      it "does not raise an error" do
        expect { decoded_credentials }.to_not raise_error
      end

      it "parses the jwt claim expectedly" do
        expect(decoded_credentials.jwt).to eq(valid_token)
      end
    end

    context "with empty request body" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(empty_authenticate_token_request)
      end

      it "raises a MissingRequestParam error" do
        expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
      end
    end

    context "with no jwt parameter in the request" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(authenticate_token_request_missing_jwt_parameter)
      end

      it "raises a MissingRequestParam error" do
        expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
      end
    end

    context "with an empty jwt token in the request" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(prefix)
      end

      it "raises a MissingRequestParam error" do
        expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
      end
    end

    context "with invalid JWT token #1" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(header_body)
      end

      it "raises a RequestBodyIsNotJWTToken error" do
        expect { subject }.to raise_error(::Errors::Authentication::Jwt::RequestBodyMissingJWTToken)
      end
    end

    context "with invalid JWT token #2" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(header_body_period)
      end

      it "raises a RequestBodyIsNotJWTToken error" do
        expect { subject }.to raise_error(::Errors::Authentication::Jwt::RequestBodyMissingJWTToken)
      end
    end

    context "with invalid JWT token #3" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(header_signature)
      end

      it "raises a RequestBodyIsNotJWTToken error" do
        expect { subject }.to raise_error(::Errors::Authentication::Jwt::RequestBodyMissingJWTToken)
      end
    end

    context "with JWT token contains a control character" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(control_character_token_request)
      end

      it "raises a RequestBodyIsNotJWTToken error" do
        expect { subject }.to raise_error(::Errors::Authentication::Jwt::RequestBodyMissingJWTToken)
      end
    end

    context "with JWT token ends by new line" do
      subject(:decoded_credentials) do
        ::Authentication::Jwt::DecodedCredentials.new(new_line_token_request)
      end

      it "does not raise an error" do
        expect { decoded_credentials }.to_not raise_error
      end

      it "parses the jwt claim expectedly" do
        expect(decoded_credentials.jwt).to eq(valid_token)
      end
    end

  end
end
