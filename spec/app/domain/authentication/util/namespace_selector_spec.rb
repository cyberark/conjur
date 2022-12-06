# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Util::NamespaceSelector) do
  describe '#select' do
    context 'when type is a supported authenticator type' do
      context 'when type is `authn-oidc`' do
        context 'when pkce support feature flag is enabled' do
          it 'returns the valid namespace' do
            expect(
              Authentication::Util::NamespaceSelector.select(
                authenticator_type: 'authn-oidc',
                pkce_support_enabled: true
              )
            ).to eq('Authentication::AuthnOidc::PkceSupportFeature')
          end
        end

        context 'when pkce support feature flag is disabled' do
          it 'returns the valid namespace' do
            expect(
              Authentication::Util::NamespaceSelector.select(
                authenticator_type: 'authn-oidc',
                pkce_support_enabled: false
              )
            ).to eq('Authentication::AuthnOidc::V2')
          end
        end
      end
    end
    context 'when type is not supported' do
      context 'when type is `authn-k8s`' do
        it 'raises an error' do
          expect {
            Authentication::Util::NamespaceSelector.select(
              authenticator_type: 'authn-k8s'
            )
          }.to raise_error(RuntimeError, "'authn-k8s' is not a supported authenticator type")
        end
      end
      context 'when type is missing' do
        it 'raises an error' do
          expect {
            Authentication::Util::NamespaceSelector.select(
              authenticator_type: nil
            )
          }.to raise_error(RuntimeError, "'' is not a supported authenticator type")
        end
      end
    end
  end
end
