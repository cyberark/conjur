# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey') do

  let(:log_output) { StringIO.new }
  let(:logger) {
    Logger.new(
      log_output,
      formatter: proc do | severity, time, progname, msg |
        "#{severity},#{msg}\n"
      end)
  }

  let(:provider_uri) { "https://provider-uri.com/provider" }
  let(:required_discover_identity_error) { "Provider uri identity error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_fetch_signing_key) { double("MockedFetchSigningKey") }
  let(:mocked_fetch_signing_key_refresh_value) { double("MockedFetchSigningKeyRefreshValue") }
  let(:mocked_discover_identity_provider) { double("Mocked discover identity provider")  }
  let(:mocked_invalid_uri_discover_identity_provider) { double("Mocked invalid uri discover identity provider")  }
  let(:mocked_provider_uri) { double("Mocked provider uri")  }

  let(:mocked_valid_discover_identity_result) { "some jwks" }
  let(:valid_jwks_result) { {:keys=> mocked_valid_discover_identity_result} }

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

    allow(mocked_discover_identity_provider).to(
      receive(:call).and_return(mocked_provider_uri)
    )

    allow(mocked_provider_uri).to(
      receive(:jwks).and_return(mocked_valid_discover_identity_result)
    )

    allow(mocked_invalid_uri_discover_identity_provider).to(
      receive(:call).and_raise(required_discover_identity_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchProviderUriSigningKey call " do
    context "propagates refresh value" do
      context "false" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(provider_uri: provider_uri,
                                                                                 fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                                 logger: mocked_logger,
                                                                                 discover_identity_provider: mocked_discover_identity_provider
          ).call(force_fetch: false)
        end

        it "returns false" do
          expect(subject).to eql(false)
        end
      end

      context "true" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(provider_uri: provider_uri,
                                                                                 fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                                 logger: mocked_logger,
                                                                                 discover_identity_provider: mocked_discover_identity_provider
          ).call(force_fetch: true)
        end

        it "returns true" do
          expect(subject).to eql(true)
        end
      end
    end

    context "'provider-uri' value is" do
      context "invalid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(provider_uri: provider_uri,
                                                                                 fetch_signing_key: mocked_fetch_signing_key,
                                                                                 logger: mocked_logger,
                                                                                 discover_identity_provider: mocked_invalid_uri_discover_identity_provider
          ).call(force_fetch: false)
        end

        it "raises an error" do
          expect { subject }.to raise_error(required_discover_identity_error)
        end
      end

      context "valid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(provider_uri: provider_uri,
                                                                                 fetch_signing_key: mocked_fetch_signing_key,
                                                                                 logger: logger,
                                                                                 discover_identity_provider: mocked_discover_identity_provider
          ).call(force_fetch: false)
        end

        it "does not raise error and write appropriate logs" do
          expect(subject).to eql(valid_jwks_result)
          expect(log_output.string.split("\n")).to eq([
                                                        "INFO,CONJ00072I Fetching JWKS from 'https://provider-uri.com/provider'...",
                                                        "DEBUG,CONJ00009D Fetched Identity Provider keys from provider successfully"
                                                      ])
        end
      end
    end
  end
end
