# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe('Authentication::AuthnJwt::FetchJwksUriSigningKey') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:required_jwks_uri_configuration_error) { "required jwks_uri configuration missing error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_authenticator_params) { double("mocked authenticator params")  }
  let(:mocked_fetch_required_existing_secret) { double("mocked fetch required existing secret")  }
  let(:mocked_fetch_required_empty_secret) { double("mocked fetch required empty secret")  }
  let(:mocked_resource_value_not_exists) { double("Mocked resource value not exists")  }
  let(:mocked_resource_value_exists) { double("Mocked resource value exists")  }
  let(:mocked_bad_http_response) { double("Mocked bad http response")  }
  let(:mocked_good_http_response) { double("Mocked good http response")  }
  let(:mocked_bad_response) { double("Mocked bad http body")  }
  let(:mocked_good_response) { double("Mocked good http body")  }

  let(:mocked_valid_jwks_result) { JSON.parse('{"keys":[{"kty":"RSA","kid":"FirstKid","e":"AQAB","n":"FirstJwtToken","use":"sig","alg":"RS256"},{"kty":"RSA","kid":"secondKid","e":"AQAB","n":"SecondJwtToken","use":"sig","alg":"RS256"}]}'.to_json)['keys'] }

  before(:each) do
    allow(mocked_logger).to(
      receive(:call).and_return(true)
    )

    allow(mocked_logger).to(
      receive(:debug).and_return(true)
    )

    allow(mocked_authenticator_params).to(
      receive(:authenticator_resource_id).and_return('resource_id')
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
      receive(:get_response).and_return(mocked_bad_response)
    )

    allow(mocked_good_http_response).to(
      receive(:get_response).and_return(mocked_good_response)
    )

    allow(mocked_good_response).to(
      receive(:body).and_return('{"keys":[{"kty":"RSA","kid":"FirstKid","e":"AQAB","n":"FirstJwtToken","use":"sig","alg":"RS256"},{"kty":"RSA","kid":"secondKid","e":"AQAB","n":"SecondJwtToken","use":"sig","alg":"RS256"}]}'.to_json)
    )

    allow(mocked_bad_response).to(
      receive(:body).and_return(nil)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchJwksUriSigningKey has_valid_configuration " do
    context "'jwks-uri' variable is not configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchJwksUriSigningKey.new(authenticator_parameters: mocked_authenticator_params,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_not_exists,
                                                               http: mocked_good_http_response).has_valid_configuration?
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_jwks_uri_configuration_error)
      end
    end

    context "'jwks-uri' variable is configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchJwksUriSigningKey.new(authenticator_parameters: mocked_authenticator_params,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_exists,
                                                               http: mocked_good_http_response).has_valid_configuration?
      end

      it "does not raise error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "FetchJwksUriSigningKey fetch_signing_key " do
    context "'jwks-uri' secret is not valid" do
      subject do
        ::Authentication::AuthnJwt::FetchJwksUriSigningKey.new(authenticator_parameters: mocked_authenticator_params,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_exists,
                                                               http: mocked_http).fetch_signing_key
      end

      it "raises an error" do
        expect { subject }.to raise_error
      end
    end

    context "'jwks-uri' secret is valid" do
      subject do
        ::Authentication::AuthnJwt::FetchJwksUriSigningKey.new(authenticator_parameters: mocked_authenticator_params,
                                                               logger: mocked_logger,
                                                               fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                               resource_class: mocked_resource_value_exists,
                                                               http: mocked_good_http_response).fetch_signing_key
      end

      it "does not raise error" do
        puts("**************************************" + mocked_valid_jwks_result)
        expect(subject).to eql(mocked_valid_jwks_result)
      end
    end
  end
end
