# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::FetchProviderUriSigningKey') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }

  let(:required_provider_uri_configuration_error) { "required provider_uri configuration missing error" }
  let(:mocked_logger) { double("Mocked Logger")  }
  let(:mocked_authenticator_params) { double("mocked authenticator params")  }
  let(:mocked_fetch_required_existing_secret) { double("mocked fetch required existing secret")  }
  let(:mocked_fetch_required_empty_secret) { double("mocked fetch required empty secret")  }
  let(:mocked_resource_value_not_exists) { double("Mocked resource value not exists")  }
  let(:mocked_resource_value_exists) { double("Mocked resource value exists")  }
  let(:mocked_discover_identity_provider) { double("Mocked discover identity provider")  }
  let(:mocked_provider_uri) { double("Mocked provider uri")  }

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
      receive(:jwks).and_return("Some Jwks")
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "FetchproviderUriSigningKey has_valid_configuration " do
    context "'provider-uri' variable is not configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchProviderUriSigningKey.new(mocked_authenticator_params,
                                                                   mocked_logger,
                                                                   mocked_fetch_required_existing_secret,
                                                                   mocked_resource_value_not_exists,
                                                                   mocked_discover_identity_provider).has_valid_configuration?
      end

      it "raises an error" do
        expect { subject }.to raise_error(required_provider_uri_configuration_error)
      end
    end

    context "'provider-uri' variable is configured in authenticator policy" do
      subject do
        ::Authentication::AuthnJwt::FetchProviderUriSigningKey.new(mocked_authenticator_params,
                                                                   mocked_logger,
                                                                   mocked_fetch_required_existing_secret,
                                                                   mocked_resource_value_exists,
                                                                   mocked_discover_identity_provider).has_valid_configuration?
      end

      it "does not raise error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
