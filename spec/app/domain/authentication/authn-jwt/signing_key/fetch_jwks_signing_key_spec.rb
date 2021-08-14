# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey') do

  let(:authenticator_name) { "authn-jwt" }
  let(:service_id) { "my-service" }
  let(:account) { "my-account" }
  let(:mocked_authentication_parameters) {
    Authentication::AuthnJwt::AuthenticationParameters.new(
      authentication_input: Authentication::AuthenticatorInput.new(
        authenticator_name: authenticator_name,
        service_id: service_id,
        account: account,
        username: "dummy_identity",
        credentials: "dummy",
        client_ip: "dummy",
        request: "dummy"
      ),
      jwt_token: nil
    )
  }

  let(:required_jwks_uri_configuration_error) { "required jwks_uri configuration missing error" }
  let(:bad_response_error) { "bad response error" }
  let(:required_secret_missing_error) { "required secret missing error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_fetch_authenticator_secrets_exist_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:mocked_fetch_authenticator_secrets_empty_values)  {  double("MockedFetchAuthenticatorSecrets") }
  let(:mocked_bad_http_response) { double("Mocked bad http response")  }
  let(:mocked_good_http_response) { double("Mocked good http response")  }
  let(:mocked_bad_response) { double("Mocked bad http body")  }
  let(:mocked_good_response) { double("Mocked good http body")  }
  let(:mocked_create_jwks_from_http_response) { double("Mocked good jwks")  }

  let(:good_response) { "good-response"}
  let(:bad_response) { "bad-response"}
  let(:valid_jwks) { "valid-jwls" }

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

    allow(mocked_fetch_authenticator_secrets_exist_values).to(
      receive(:call).and_return('jwks-uri' => 'https://jwks-uri.com/jwks')
    )

    allow(mocked_fetch_authenticator_secrets_empty_values).to(
      receive(:call).and_raise(required_secret_missing_error)
    )

    allow(mocked_bad_http_response).to(
      receive(:get_response).and_return(bad_response)
    )

    allow(mocked_good_http_response).to(
      receive(:get_response).and_return(good_response)
    )

    allow(mocked_create_jwks_from_http_response).to(
      receive(:call).with(http_response: good_response).and_return(valid_jwks)
    )

    allow(mocked_create_jwks_from_http_response).to(
      receive(:call).with(http_response: bad_response).and_raise(bad_response_error)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/



  context "FetchJwksUriSigningKey fetch_signing_key " do
    context "'jwks-uri' secret is not valid" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                               logger: mocked_logger,
                                                               fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
                                                               http_lib: mocked_bad_http_response,
                                                               create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).fetch_signing_key
      end

      it "raises an error" do
        expect { subject }.to raise_error(bad_response_error)
      end
    end

    context "'jwks-uri' secret is valid" do
      context "provider return valid http response" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                 logger: mocked_logger,
                                                                 fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
                                                                 http_lib: mocked_good_http_response,
                                                                 create_jwks_from_http_response: mocked_create_jwks_from_http_response
          ).fetch_signing_key
        end

        it "returns jwks value" do
          expect(subject).to eql(valid_jwks)
        end
      end

      context "provider return bad http response" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                 logger: mocked_logger,
                                                                 fetch_authenticator_secrets: mocked_fetch_authenticator_secrets_exist_values,
                                                                 http_lib: mocked_bad_http_response,
                                                                 create_jwks_from_http_response: mocked_create_jwks_from_http_response
          ).fetch_signing_key
        end

        it "raises an error" do
          expect { subject }.to raise_error(bad_response_error)
        end
      end
    end
  end
end
