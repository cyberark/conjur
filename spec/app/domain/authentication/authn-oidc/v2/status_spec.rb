# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(' Authentication::AuthnOidc::V2::Status') do
  describe '.call' do
    let(:namespace_selector) do
      class_double(::Authentication::Util::NamespaceSelector).tap do |double|
        allow(double).to receive(:select).and_return('Authentication::AuthnOidc::PkceSupportFeature')
      end
    end

    let(:status) do
      Authentication::AuthnOidc::V2::Status.new(
        available_authenticators: ['authn-oidc/foo', 'authn-oidc/okta-2'],
        oidc_client: oidc_client,
        namespace_selector: namespace_selector,
        variable_repository: variable_repository,
        authenticator_repository: authenticator_repository
      )
    end

    let(:authenticator_repository) do
      class_double(DB::Repository::AuthenticatorRepository).tap do |instance_double|
        allow(instance_double).to receive(:new).and_return(
          instance_double(DB::Repository::AuthenticatorRepository).tap do |double|
            allow(double).to receive(:find).and_return(data_object)
          end
        )
      end
    end

    let(:data_object) { double }

    let(:oidc_client) do
      class_double(::Authentication::AuthnOidc::V2::Client).tap do |instance_double|
        allow(instance_double).to receive(:new).and_return(oidc_instance_client)
      end
    end

    let(:oidc_instance_client) do
      instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
        allow(double).to receive(:oidc_client).and_return(true)
      end
    end

    let(:variable_repository) do
      instance_double(DB::Repository::VariablesRepository).tap do |double|
        allow(double).to receive(:find_by_id_path).and_return(variables)
      end
    end

    let(:variables) { {} }

    context 'when authenticator is not enabled' do
      it 'raises an exception' do
        expect do
          status.call(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta'
          )
        end.to raise_error(
          Errors::Authentication::Security::AuthenticatorNotWhitelisted,
          "CONJ00004E 'authn-oidc/okta' is not enabled"
        )
      end
    end

    context 'when oidc endpoint is not available' do
      let(:oidc_instance_client) do
        instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
          allow(double).to receive(:oidc_client).and_raise(Errors::Authentication::OAuth::ProviderDiscoveryFailed)
        end
      end

      it 'raises an exception' do
        expect do
          status.call(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta-2'
          )
        end.to raise_error(
          Errors::Authentication::OAuth::ProviderDiscoveryFailed
        )
      end
    end

    context 'when required variables are not set' do
      # Need to ensure we make it to the last check
      let(:data_object) { nil }

      context 'when variable are missing' do
        let(:variables) do
          {
            "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
            "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
            "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
            "cucumber:variable:conjur/authn-oidc/okta-2/redirect_uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
          }
        end

        it 'raises an error' do
          expect do
            status.call(
              account: 'cucumber',
              authenticator_type: 'authn-oidc',
              service_id: 'okta-2'
            )
          end.to raise_error(
            Errors::Conjur::RequiredResourceMissing,
            "CONJ00036E Missing required resource: 'cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping'"
          )
        end
      end

      context 'when variable are missing' do
        let(:variables) do
          {
            "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
            "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
            "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
            "cucumber:variable:conjur/authn-oidc/okta-2/redirect-uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
            "cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping" => nil
          }
        end

        it 'raises an error' do
          expect do
            status.call(
              account: 'cucumber',
              authenticator_type: 'authn-oidc',
              service_id: 'okta-2'
            )
          end.to raise_error(
            Errors::Conjur::RequiredSecretMissing,
            "CONJ00037E Missing value for resource: 'cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping'"
          )
        end
      end
    end
  end

  describe '.authenticator_enabled?' do
    let(:status) do
      Authentication::AuthnOidc::V2::Status.new(
        available_authenticators: ['authn-oidc/foo', 'authn-oidc/bar']
      )
    end
    context 'when authenticator is enabled' do
      it 'does not raise an error' do
        expect { status.authenticator_enabled?(authenticator_name: 'authn-oidc/bar') }.not_to raise_error
      end
    end

    context 'when authenticator is disabled' do
      it 'does not raise an error' do
        expect { status.authenticator_enabled?(authenticator_name: 'authn-oidc/baz') }.to raise_error(
          Errors::Authentication::Security::AuthenticatorNotWhitelisted,
          "CONJ00004E 'authn-oidc/baz' is not enabled"
        )
      end
    end
  end

  describe '.check_for_missing_variables' do
    let(:namespace_selector) do
      class_double(::Authentication::Util::NamespaceSelector).tap do |double|
        allow(double).to receive(:select).and_return('Authentication::AuthnOidc::PkceSupportFeature')
      end
    end

    let(:status) do
      Authentication::AuthnOidc::V2::Status.new(
        available_authenticators: nil,
        namespace_selector: namespace_selector,
        variable_repository: variable_repository
      )
    end

    let(:variable_repository) do
      instance_double(DB::Repository::VariablesRepository).tap do |double|
        allow(double).to receive(:find_by_id_path).and_return(variables)
      end
    end

    context 'when extra Conjur variables and values are present' do
      let(:variables) do
        {
          "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
          "cucumber:variable:conjur/authn-oidc/okta-2/redirect_uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
          "cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping" => "preferred_username",
          "cucumber:variable:conjur/authn-oidc/okta-2/nonce" => "1656b4264b60af659fce",
          "cucumber:variable:conjur/authn-oidc/okta-2/state" => "4f413476ef7e2395f0af"
        }
      end

      it 'does not raise an error' do
        expect do
          status.check_for_missing_variables(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta-2'
          )
        end.not_to raise_error
      end
    end

    context 'when Conjur variables are missing from policy' do
      let(:variables) do
        {
          "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
          "cucumber:variable:conjur/authn-oidc/okta-2/redirect_uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
        }
      end

      it 'raise an error' do
        expect do
          status.check_for_missing_variables(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta-2'
          )
        end.to raise_error(
          Errors::Conjur::RequiredResourceMissing,
          "CONJ00036E Missing required resource: 'cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping'"
        )
      end
    end

    context 'when Conjur variable values are missing' do
      let(:variables) do
        {
          "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
          "cucumber:variable:conjur/authn-oidc/okta-2/redirect_uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
          "cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping" => nil
        }
      end

      it 'raise an error' do
        expect do
          status.check_for_missing_variables(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta-2'
          )
        end.to raise_error(
          Errors::Conjur::RequiredSecretMissing,
          "CONJ00037E Missing value for resource: 'cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping'"
        )
      end
    end

    context 'when Conjur variables and values are present' do
      let(:variables) do
        {
          "cucumber:variable:conjur/authn-oidc/okta-2/provider-uri" => "https://conjur-test.okta.com/oauth2/default",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-id" => "conjur-client-id",
          "cucumber:variable:conjur/authn-oidc/okta-2/client-secret" => "conjur-client-secret",
          "cucumber:variable:conjur/authn-oidc/okta-2/redirect_uri" => "http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate",
          "cucumber:variable:conjur/authn-oidc/okta-2/claim-mapping" => "preferred_username"
        }
      end

      it 'does not raise an error' do
        expect do
          status.check_for_missing_variables(
            account: 'cucumber',
            authenticator_type: 'authn-oidc',
            service_id: 'okta-2'
          )
        end.not_to raise_error
      end
    end
  end

  describe '.verify_connection' do
    let(:status) do
      Authentication::AuthnOidc::V2::Status.new(
        available_authenticators: nil,
        oidc_client: oidc_client
      )
    end

    let(:oidc_client) do
      class_double(::Authentication::AuthnOidc::V2::Client).tap do |instance_double|
        allow(instance_double).to receive(:new).and_return(response)
      end
    end

    context 'when connection is successful' do
      let(:response) do
        instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
          allow(double).to receive(:oidc_client).and_return(nil)
        end
      end

      it 'does not raise an exception' do
        expect { status.verify_connection(authenticator: double) }.not_to raise_error
      end
    end

    context 'when connection fails' do
      let(:response) do
        instance_double(::Authentication::AuthnOidc::V2::Client).tap do |double|
          allow(double).to receive(:oidc_client).and_raise(exception)
        end
      end

      context 'due to a network timeout' do
        let(:exception) { Errors::Authentication::OAuth::ProviderDiscoveryTimeout }
        it 'raise an exception' do
          expect do
            status.verify_connection(authenticator: double)
          end.to raise_error(
            Errors::Authentication::OAuth::ProviderDiscoveryTimeout
          )
        end
      end

      context 'can not find discovery endpoint' do
        let(:exception) { Errors::Authentication::OAuth::ProviderDiscoveryFailed }
        it 'raise an exception' do
          expect do
            status.verify_connection(authenticator: double)
          end.to raise_error(
            Errors::Authentication::OAuth::ProviderDiscoveryFailed
          )
        end
      end
    end
  end
end
