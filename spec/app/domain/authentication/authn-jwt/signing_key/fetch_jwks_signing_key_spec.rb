# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey') do

  let(:log_output) { StringIO.new }
  let(:logger) {
    Logger.new(
      log_output,
      formatter: proc do | severity, time, progname, msg |
        "#{severity},#{msg}\n"
      end)
  }

  let(:jwks_uri_https) { "https://jwks-uri.com/jwks" }
  let(:jwks_uri_http) { "http://jwks-uri.com/jwks" }
  let(:bad_response_error) { "bad response error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_fetch_signing_key) { double("MockedFetchSigningKey") }
  let(:mocked_fetch_signing_key_refresh_value) { double("MockedFetchSigningKeyRefreshValue") }
  let(:mocked_bad_http_response) { double("Mocked bad http response")  }
  let(:mocked_good_http_response) { double("Mocked good http response")  }
  let(:mocked_http_response_ca_cert_present) { double("MockedNet::HTTP.startCertStorePresent") }
  let(:mocked_bad_response) { double("Mocked bad http body")  }
  let(:mocked_good_response) { double("Mocked good http body")  }
  let(:mocked_create_jwks_from_http_response) { double("Mocked good jwks")  }
  let(:mocked_create_jwks_from_http_responce_http_response) { double("MockedDummyJwks") }

  let(:good_response) { "good-response"}
  let(:bad_response) { "bad-response"}
  let(:valid_jwks) { "valid-jwls" }
  let(:cert_store_present) { "present" }
  let(:cert_store_absent) { "absent" }

  before(:each) do
    allow(mocked_logger).to(
      receive(:call).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:debug).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:info).and_return(true)
    )

    allow(mocked_fetch_signing_key).to receive(:call) { |params| params[:signing_key_provider].fetch_signing_key }
    allow(mocked_fetch_signing_key_refresh_value).to receive(:call) { |params| params[:refresh] }

    allow(mocked_bad_http_response).to(
      receive(:start).and_return(bad_response)
    )

    allow(mocked_good_http_response).to(
      receive(:start).and_return(good_response)
    )

    allow(mocked_http_response_ca_cert_present).to(
      receive(:start).with(
        anything,
        anything,
        use_ssl: anything,
        cert_store: cert_store_present
      ).and_return(cert_store_present)
    )

    allow(mocked_http_response_ca_cert_present).to(
      receive(:start).with(
        anything,
        anything,
        use_ssl: anything
      ).and_return(cert_store_absent)
    )

    allow(mocked_create_jwks_from_http_response).to(
      receive(:call).with(http_response: good_response).and_return(valid_jwks)
    )

    allow(mocked_create_jwks_from_http_response).to(
      receive(:call).with(http_response: bad_response).and_raise(bad_response_error)
    )

    allow(mocked_create_jwks_from_http_responce_http_response).to receive(:call) { |params| params[:http_response] }
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchJwksUriSigningKey call " do
    context "propagates false refresh value" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                           fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                           logger: mocked_logger,
                                                                           http_lib: mocked_bad_http_response,
                                                                           create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).call(force_fetch: false)
      end

      it "returns false" do
        expect(subject).to eql(false)
      end
    end

    context "propagates true refresh value" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                           fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                           logger: mocked_logger,
                                                                           http_lib: mocked_bad_http_response,
                                                                           create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).call(force_fetch: true)
      end

      it "returns true" do
        expect(subject).to eql(true)
      end
    end

    context "processes ca_cert parameter" do
      context "when it present" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                             cert_store: cert_store_present,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             http_lib: mocked_http_response_ca_cert_present,
                                                                             create_jwks_from_http_response: mocked_create_jwks_from_http_responce_http_response
          ).call(force_fetch: false)
        end

        it "returns valid value" do
          expect(subject).to eql(cert_store_present)
        end
      end

      context "when it present but uri is http" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_http,
                                                                             cert_store: cert_store_present,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             http_lib: mocked_http_response_ca_cert_present,
                                                                             create_jwks_from_http_response: mocked_create_jwks_from_http_responce_http_response
          ).call(force_fetch: false)
        end

        it "raises error" do
          expect { subject }.to raise_error(
                                  Errors::Authentication::AuthnJwt::FetchJwksKeysFailed,
                                  /CONJ00087E Failed to fetch JWKS from 'http:\/\/jwks-uri.com\/jwks'. Reason: 'TLS misconfiguration - ca-cert is provided but jwks-uri URI scheme is http'/
                                )
        end
      end

      context "when it's absent" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             http_lib: mocked_http_response_ca_cert_present,
                                                                             create_jwks_from_http_response: mocked_create_jwks_from_http_responce_http_response
          ).call(force_fetch: false)
        end

        it "returns valid value" do
          expect(subject).to eql(cert_store_absent)
        end
      end
    end

    context "provider return valid http response" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                           fetch_signing_key: mocked_fetch_signing_key,
                                                                           logger: logger,
                                                                           http_lib: mocked_good_http_response,
                                                                           create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).call(force_fetch: false)
      end

      it "returns jwks value and writes appropriate logs" do
        expect(subject).to eql(valid_jwks)
        expect(log_output.string.split("\n")).to eq([
                                                      "INFO,CONJ00072I Fetching JWKS from 'https://jwks-uri.com/jwks'...",
                                                      "DEBUG,CONJ00073D Successfully fetched JWKS"
                                                    ])
      end
    end

    context "provider return bad http response" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(jwks_uri: jwks_uri_https,
                                                                           fetch_signing_key: mocked_fetch_signing_key,
                                                                           logger: mocked_logger,
                                                                           http_lib: mocked_bad_http_response,
                                                                           create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).call(force_fetch: false)
      end

      it "raises an error" do
        expect { subject }.to raise_error(bad_response_error)
      end
    end
  end
end
