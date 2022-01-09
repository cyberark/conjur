# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey') do

  let(:authenticator_name) { "authn-jwt" }
  let(:service_id) { "my-service" }
  let(:account) { "my-account" }
  let(:mocked_authenticator_input) {
    Authentication::AuthenticatorInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      credentials: "dummy",
      client_ip: "dummy",
      request: "dummy"
    )
  }

  let(:required_jwks_uri_configuration_error) { "required jwks_uri configuration missing error" }
  let(:bad_response_error) { "bad response error" }
  let(:required_secret_missing_error) { "required secret missing error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_fetch_signing_key) { double("MockedFetchSigningKey") }
  let(:mocked_fetch_signing_key_refresh_value) { double("MockedFetchSigningKeyRefreshValue") }
  let(:mocked_fetch_authenticator_secrets_exist_https)  {  double("MockedFetchAuthenticatorSecretsHttps") }
  let(:mocked_fetch_authenticator_secrets_exist_http)  {  double("MockedFetchAuthenticatorSecretsHttp") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MockedFetchAuthenticatorSecretsEmpty") }
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

    allow(mocked_fetch_authenticator_secrets_exist_https).to(
      receive(:call).and_return('jwks-uri' => 'https://jwks-uri.com/jwks')
    )

    allow(mocked_fetch_authenticator_secrets_exist_http).to(
      receive(:call).and_return('jwks-uri' => 'http://jwks-uri.com/jwks')
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

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
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                           fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                           logger: mocked_logger,
                                                                           fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
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
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                           fetch_signing_key: mocked_fetch_signing_key_refresh_value,
                                                                           logger: mocked_logger,
                                                                           fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
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
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                             ca_cert: cert_store_present,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
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
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                             ca_cert: cert_store_present,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_http,
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
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
                                                                             http_lib: mocked_http_response_ca_cert_present,
                                                                             create_jwks_from_http_response: mocked_create_jwks_from_http_responce_http_response
          ).call(force_fetch: false)
        end

        it "returns valid value" do
          expect(subject).to eql(cert_store_absent)
        end
      end
    end

    context "'jwks-uri' secret is not valid" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                           fetch_signing_key: mocked_fetch_signing_key,
                                                                           logger: mocked_logger,
                                                                           fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
                                                                           http_lib: mocked_bad_http_response,
                                                                           create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).call(force_fetch: false)
      end

      it "raises an error" do
        expect { subject }.to raise_error(bad_response_error)
      end
    end

    context "'jwks-uri' secret is valid" do
      context "provider return valid http response" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
                                                                             http_lib: mocked_good_http_response,
                                                                             create_jwks_from_http_response: mocked_create_jwks_from_http_response
          ).call(force_fetch: false)
        end

        it "returns jwks value" do
          expect(subject).to eql(valid_jwks)
        end
      end

      context "provider return bad http response" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authenticator_input: mocked_authenticator_input,
                                                                             fetch_signing_key: mocked_fetch_signing_key,
                                                                             logger: mocked_logger,
                                                                             fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_https,
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
end
