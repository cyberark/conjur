# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:required_provider_uri_configuration_error) { "required provider_uri configuration missing error" }
  let(:required_discover_identity_error) { "Provider uri identity error" }

  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_authentication_parameters) { double("mocked authenticator params")  }
  let(:mocked_fetch_required_existing_secret) { double("mocked fetch required existing secret")  }
  let(:mocked_fetch_required_empty_secret) { double("mocked fetch required empty secret")  }
  let(:mocked_resource_value_not_exists) { double("Mocked resource value not exists")  }
  let(:mocked_resource_value_exists) { double("Mocked resource value exists")  }
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

    allow(mocked_authentication_parameters).to(
      receive(:authn_jwt_variable_id).and_return('resource_id')
    )

    allow(mocked_fetch_required_existing_secret).to(
      receive(:[]).and_return('resource_id/provider-uri' => 'https://provider-uri.com/provider')
    )

    allow(mocked_fetch_required_existing_secret).to(
      receive(:call).and_return('resource_id/provider-uri' => 'https://provider-uri.com/provider')
    )

    allow(mocked_fetch_required_empty_secret).to(
      receive(:[]).and_return(nil)
    )

    allow(mocked_resource_value_not_exists).to(
      receive(:[]).and_raise(required_provider_uri_configuration_error)
    )

    allow(mocked_resource_value_exists).to(
      receive(:[]).and_return("resource")
    )

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

  context "FetchProviderUriSigningKey has_valid_configuration " do
    context "'provider-uri' variable is not configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                   logger: mocked_logger,
                                                                   fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                   resource_class: mocked_resource_value_not_exists,
                                                                   discover_identity_provider: mocked_discover_identity_provider).valid_configuration?
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_provider_uri_configuration_error)
      end
    end

    context "'provider-uri' value is valid" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                   logger: mocked_logger,
                                                                   fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                   resource_class: mocked_resource_value_exists,
                                                                   discover_identity_provider: mocked_discover_identity_provider).valid_configuration?
      end

      it "does not raise error" do
        expect(subject).to eql(true)
      end
    end
  end

  context "FetchProviderUriSigningKey fetch_signing_key " do
    context "'provider-uri' variable is configured in authenticator policy" do
      context "'provider-uri' value is invalid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                     logger: mocked_logger,
                                                                     fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                     resource_class: mocked_resource_value_exists,
                                                                     discover_identity_provider: mocked_invalid_uri_discover_identity_provider).call
        end

        it "raises an error" do
          expect { subject }.to raise_error(required_discover_identity_error)
        end
      end

      context "'provider-uri' value is valid" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new(authentication_parameters: mocked_authentication_parameters,
                                                                     logger: mocked_logger,
                                                                     fetch_required_secrets: mocked_fetch_required_existing_secret,
                                                                     resource_class: mocked_resource_value_exists,
                                                                     discover_identity_provider: mocked_discover_identity_provider).call
        end

        it "does not raise error" do
          expect(subject).to eql(valid_jwks_result)
        end
      end
    end
  end
end
