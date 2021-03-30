# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::Jwt::DecodedCredentials') do
  ####################################
  # request mock
  ####################################

  def mock_authenticate_token_request(request_body_data:)
    double('JwtRequest').tap do |request|
      request_body = StringIO.new
      request_body.puts(request_body_data)
      request_body.rewind

      allow(request).to receive(:body).and_return(request_body)
    end
  end

  def request_body(request)
    request.body.read.chomp
  end

  let(:valid_jwt_claim_value) do
    "{\"jwt_claim\": \"jwt_claim_value\"}"
  end

  let(:authenticate_token_request) do
    mock_authenticate_token_request(request_body_data: "jwt=#{valid_jwt_claim_value}")
  end

  let(:authenticate_token_request_missing_jwt_claim) do
    mock_authenticate_token_request(request_body_data: "some_key=some_value")
  end

  let(:authenticate_token_request_empty_jwt_claim) do
    mock_authenticate_token_request(request_body_data: "jwt=")
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Credentials" do
    context "with a jwt claim" do
      subject(:decoded_credentials) do
        ::Authentication::Jwt::DecodedCredentials.new(
          request_body(authenticate_token_request)
        )
      end

      it "does not raise an error" do
        expect { decoded_credentials }.to_not raise_error
      end

      it "parses the jwt claim expectedly" do
        expect(decoded_credentials.jwt).to eq(valid_jwt_claim_value)
      end
    end

    context "with no jwt claim in the request" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(
          request_body(authenticate_token_request_missing_jwt_claim)
        )
      end

      it "raises a MissingRequestParam error" do
        expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
      end
    end

    context "with an empty jwt claim in the request" do
      subject do
        ::Authentication::Jwt::DecodedCredentials.new(
          request_body(authenticate_token_request_empty_jwt_claim)
        )
      end

      it "raises a MissingRequestParam error" do
        expect { subject }.to raise_error(::Errors::Authentication::RequestBody::MissingRequestParam)
      end
    end
  end
end
