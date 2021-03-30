# frozen_string_literal: true

RSpec.describe(Authentication::Jwt::VerifyAndDecodeToken) do
  let(:token_jwt) { "decoded_token" }
  let(:mock_decoded_token) { [token_jwt] }
  let(:verification_options) { {} }

  def mock_jwt_decoder(error:)
    double('JWT').tap do |jwt_decoder|
      if error
        allow(jwt_decoder).to receive(:decode)
          .and_raise(error)
      else
        allow(jwt_decoder).to receive(:decode)
          .and_return(mock_decoded_token)
      end
    end
  end

  context "JWT decoder succeeds to verify and decode the token" do
    subject do
      Authentication::Jwt::VerifyAndDecodeToken.new(
        jwt_decoder: mock_jwt_decoder(error: false)
      ).call(
        token_jwt: token_jwt,
        verification_options: verification_options
      )
    end

    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end

    it "returns the decoded token" do
      expect(subject).to eq(token_jwt)
    end
  end

  context "JWT decoder fails to decode the token" do
    subject do
      Authentication::Jwt::VerifyAndDecodeToken.new(
        jwt_decoder: mock_jwt_decoder(error: JWT::DecodeError)
      ).call(
        token_jwt: token_jwt,
        verification_options: verification_options
      )
    end

    it "raises a TokenDecodeFailed error" do
      expect { subject }.to raise_error(Errors::Authentication::Jwt::TokenDecodeFailed)
    end

    context "where the token is expired" do
      subject do
        Authentication::Jwt::VerifyAndDecodeToken.new(
          jwt_decoder: mock_jwt_decoder(error: JWT::ExpiredSignature)
        ).call(
          token_jwt: token_jwt,
          verification_options: verification_options
        )
      end

      it "raises a TokenExpired error" do
        expect { subject }.to raise_error(Errors::Authentication::Jwt::TokenExpired)
      end
    end
  end

  context "JWT decoder fails to verify the token" do
    subject do
      Authentication::Jwt::VerifyAndDecodeToken.new(
        jwt_decoder: mock_jwt_decoder(error: StandardError)
      ).call(
        token_jwt: token_jwt,
        verification_options: verification_options
      )
    end

    it "raises a TokenVerificationFailed error" do
      expect { subject }.to raise_error(Errors::Authentication::Jwt::TokenVerificationFailed)
    end
  end
end
