# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::ResolveIdentity', type: 'unit') do
  subject do
    Authentication::AuthnOidc::V2::ResolveIdentity.new(
      authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
        account: 'rspec',
        service_id: 'bar',
        provider_uri: 'provider-uri',
        client_id: 'client-id',
        client_secret: 'client-secret',
        claim_mapping: 'claim-mapping'
      )
    )
  end

  describe('#call') do
    context 'when identity matches a role ID' do
      it 'returns the matching role' do
        expect(
          subject.call(
            identifier: 'alice',
            allowed_roles: [
              { role_id: 'rspec:user:bob' },
              { role_id: 'rspec:user:alice' }
            ]
          )
        ).to eq('rspec:user:alice')
      end

      context 'when allowed roles includes the same usernam in a different account' do
        it 'returns the matching role' do
          expect(
            subject.call(
              identifier: 'alice@foo-bar.com',
              allowed_roles: [
                { role_id: 'foo:user:alice@foo-bar.com' },
                { role_id: 'rspec:user:bob@foo-bar.com' },
                { role_id: 'foo:user:bob@foo-bar.com' },
                { role_id: 'rspec:user:alice@foo-bar.com' }
              ]
            )
          ).to eq('rspec:user:alice@foo-bar.com')
        end
      end
    end

    context 'when the provided identity does not match a role or annotation' do
      it 'raises the error RoleNotFound' do
        expect {
          subject.call(
            identifier: 'alice',
            allowed_roles: [
              { role_id: 'rspec:user:bob' },
              { role_id: 'rspec:user:chad' },
              { role_id: 'rspec:user:oidc-users/alice', annotations: { 'authn-oidc/identity' => 'alice' } }
            ]
          )
        }.to raise_error(
          Errors::Authentication::Security::RoleNotFound,
          /CONJ00007E 'alice' not found/
        )
      end
    end
  end
end
