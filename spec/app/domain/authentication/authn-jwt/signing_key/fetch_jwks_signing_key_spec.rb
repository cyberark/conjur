# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey') do

  let(:authenticator_name) { "authn-jwt" }
  let(:service_id) { "my-service" }
  let(:account) { "my-account" }

  let(:required_jwks_uri_configuration_error) { "required jwks_uri configuration missing error" }
  let(:bad_response_error) { "bad response error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_authentication_parameters) { double("mocked authenticator params")  }
  let(:mocked_fetch_required_existing_secret) { double("mocked fetch required existing secret")  }
  let(:mocked_fetch_required_empty_secret) { double("mocked fetch required empty secret")  }
  let(:mocked_resource_value_not_exists) { double("Mocked resource value not exists")  }
  let(:mocked_resource_value_exists) { double("Mocked resource value exists")  }
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

    allow(mocked_authentication_parameters).to(
      receive(:authn_jwt_variable_id_prefix).and_return('resource_id')
    )

    allow(mocked_fetch_required_existing_secret).to(
      receive(:[]).and_return('resource_id/jwks-uri' => 'https://jwks-uri.com/jwks')
    )

    allow(mocked_fetch_required_existing_secret).to(
      receive(:call).and_return('resource_id/jwks-uri' => 'https://jwks-uri.com/jwks')
    )

    allow(mocked_fetch_required_empty_secret).to(
      receive(:[]).and_return(nil)
    )

    allow(mocked_resource_value_not_exists).to(
      receive(:[]).and_raise(required_jwks_uri_configuration_error)
    )

    allow(mocked_resource_value_exists).to(
      receive(:[]).and_return("resource")
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

  context "FetchJwksUriSigningKey has_valid_configuration " do
    context "'jwks-uri' variable is not configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_not_exists,
                                                               http_lib: mocked_good_http_response,
                                                               create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).valid_configuration?
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_jwks_uri_configuration_error)
      end
    end

    context "'jwks-uri' variable is configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_exists,
                                                               http_lib: mocked_good_http_response,
                                                               create_jwks_from_http_response: mocked_create_jwks_from_http_response
        ).valid_configuration?
      end

      it "does not raise error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "FetchJwksUriSigningKey fetch_signing_key " do
    context "'jwks-uri' secret is not valid" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_exists,
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
                                                                 fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                 resource_class: mocked_resource_value_exists,
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
                                                                 fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                 resource_class: mocked_resource_value_exists,
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
