# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey) do
  let(:log_output) { StringIO.new }
  let(:logger) do
    Logger.new(
      log_output,
      formatter: proc do | severity, _time, _progname, msg|
        "#{severity},#{msg}\n"
      end
    )
  end

  let(:string_value) { "string value" }
  let(:valid_jwks) { Net::HTTP.get_response(URI("https://www.googleapis.com/oauth2/v3/certs")).body }
  let(:invalid_public_keys_value) { "{\"type\":\"invalid\", \"value\": #{valid_jwks} }" }
  let(:valid_public_keys_value) { "{\"type\":\"jwks\", \"value\": #{valid_jwks} }" }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchPublicKeysSigningKey call" do
    context "fails when the value is not a JSON" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey.new(
          signing_keys: string_value
        ).call(force_fetch: false)
      end

      it "raises error" do
        expect { subject }
          .to raise_error(JSON::ParserError)
      end
    end

    context "fails when the value is not valid" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey.new(
          signing_keys: invalid_public_keys_value
        ).call(force_fetch: false)
      end

      it "raises error", vcr: 'authenticators/authn-jwt/valid-jwks' do
        expect { subject }
          .to raise_error(Errors::Authentication::AuthnJwt::InvalidPublicKeys)
      end
    end

    context "returns a JWKS object", vcr: 'authenticators/authn-jwt/valid-jwks' do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey.new(
          signing_keys: valid_public_keys_value
        ).call(force_fetch: false)
      end

      it "JWKS object has one key", vcr: 'authenticators/authn-jwt/fetch-jwks' do
        expect(subject.length).to eql(1)
      end

      it "JWKS object key is keys", vcr: 'authenticators/authn-jwt/fetch-jwks' do
        expect(subject.key?(:keys)).to be(true)
      end

      it "JWKS object value be a JWK Set", vcr: 'authenticators/authn-jwt/fetch-jwks' do
        expect(subject[:keys]).to be_a(JSON::JWK::Set)
      end
    end

    context "writes logs" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchPublicKeysSigningKey.new(
          signing_keys: valid_public_keys_value,
          logger: logger
        ).call(force_fetch: false)
        log_output.string.split("\n")
      end

      it "as expected", vcr: 'authenticators/authn-jwt/valid-jwks' do
        expect(subject).to eql([
          "DEBUG,CONJ00143D Parsing JWKS from public-keys value...",
          "DEBUG,CONJ00144D Successfully parsed public-keys value"
        ])
      end
    end
  end
end
