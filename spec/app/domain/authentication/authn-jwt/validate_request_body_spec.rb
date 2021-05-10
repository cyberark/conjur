# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateRequestBody') do

  let(:empty) { '' }
  let(:empty_spaces) { '    ' } # what are we living for
  let(:header) { 'eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9' }
  let(:body) { 'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0' }
  let(:signature) { 'hZnl5amPk_I3tb4O-Otci_5XZdVWhPlFyVRvcqSwnDo_srcysDvhhKOD01DigPK1lJvTSTolyUgKGtpLqMfRDXQlekRsF4XhA'\
'jYZTmcynf-C-6wO5EI4wYewLNKFGGJzHAknMgotJFjDi_NCVSjHsW3a10nTao1lB82FRS305T226Q0VqNVJVWhE4G0JQvi2TssRtCxYTqzXVt22iDKkXe'\
'ZJARZ1paXHGV5Kd1CljcZtkNZYIGcwnj65gvuCwohbkIxAnhZMJXCLaVvHqv9l-AAUV7esZvkQR1IpwBAiDQJh4qxPjFGylyXrHMqh5NlT_pWL2ZoULWT'\
'g_TJjMO9TuQ' }
  let(:header_body) { header + "." + body }
  let(:header_body_period) { header + '.' + body + '.' }
  let(:header_signature) { header + '..' + signature }
  let(:token) { header + '.' + body + '.' + signature }
  let(:token_wrong_characters) { header + '#' + '.' + body + '$' + '.' + signature + '@' }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "ValidateRequestBody" do
    context "Validate request body when" do
      subject do
        Authentication::AuthnJwt::ValidateRequestBody.new()
      end

      it "the body is nil" do
        expect { subject.call(body_string: nil) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body is empty" do
        expect { subject.call(body_string: empty) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains only whitespaces" do
        expect { subject.call(body_string: empty_spaces) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains only one part of the JWT" do
        expect { subject.call(body_string: body) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains JWT without signature" do
        expect { subject.call(body_string: header_body) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains JWT without signature, last character is period" do
        expect { subject.call(body_string: header_body_period) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains JWT without body" do
        expect { subject.call(body_string: header_signature) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains JWT with illegal characters" do
        expect { subject.call(body_string: token_wrong_characters) }.to raise_error(Errors::Authentication::Jwt::RequestBodyIsNotJWTToken)
      end

      it "the body contains a valid JWT" do
        expect { subject.call(body_string: token) }.not_to raise_error
      end
    end
  end
end
