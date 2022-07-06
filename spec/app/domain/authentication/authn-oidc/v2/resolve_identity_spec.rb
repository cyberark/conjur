# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(' Authentication::AuthnOidc::V2::ResolveIdentity') do
  let(:resolve_identity) do
    Authentication::AuthnOidc::V2::ResolveIdentity.new
  end

  describe('#call') do
    let(:valid_role) do
      instance_double(::Role).tap do |double|
        allow(double).to receive(:id).and_return('rspec:user:alice')
        allow(double).to receive(:resource?).and_return(true)
      end
    end

    context 'when identity matches a role ID' do
      it 'returns the matching role' do
        expect(
          resolve_identity.call(
            account: 'rspec',
            identity: 'alice',
            allowed_roles: [ valid_role ]
          ).id
        ).to eq('rspec:user:alice')
      end

      context 'when it includes roles without resources' do
        it 'returns the matching role' do
          expect(
            resolve_identity.call(
              account: 'rspec',
              identity: 'alice',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('rspec:user:alice')
                  allow(double).to receive(:resource?).and_return(false)
                end,
                valid_role
              ]
            ).id
          ).to eq('rspec:user:alice')
        end
      end

      context 'when the accounts are different' do
        it 'returns the matching role' do
          expect(
            resolve_identity.call(
              account: 'rspec',
              identity: 'alice',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('foo:user:alice')
                  allow(double).to receive(:resource?).and_return(true)
                end,
                valid_role
              ]
            ).id
          ).to eq('rspec:user:alice')
        end
      end
    end

    context 'when the provided identity does not match a role or annotation' do
      it 'raises the error RoleNotFound' do
        expect {
          resolve_identity.call(
            account: 'rspec',
            identity: 'alice',
            allowed_roles: [
              instance_double(::Role).tap do |double|
                allow(double).to receive(:id).and_return('rspec:user:bob')
                allow(double).to receive(:resource?).and_return(true)
              end,
              instance_double(::Role).tap do |double|
                allow(double).to receive(:id).and_return('rspec:user:chad')
                allow(double).to receive(:resource?).and_return(true)
                allow(double).to receive(:resource).and_return(
                  instance_double(::Resource).tap do |resource|
                    allow(resource).to receive(:annotation).with('authn-oidc/identity').and_return('chad.example')
                  end
                )
              end
            ]
          )
        }.to raise_error(
          Errors::Authentication::Security::RoleNotFound,
          /CONJ00007E 'alice' not found/
        )
      end
    end

    context 'when the identity matches an annotation' do
      context 'when a single role matches' do
        it 'returns the role of the user' do
          expect(
            resolve_identity.call(
              account: 'rspec',
              identity: 'chad.example',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('rspec:user:chad')
                  allow(double).to receive(:resource?).and_return(true)
                  allow(double).to receive(:resource).and_return(
                    instance_double(::Resource).tap do |resource|
                      allow(resource).to receive(:annotation).with('authn-oidc/identity').and_return('chad.example')
                    end
                  )
                end
              ]
            ).id
          ).to eq('rspec:user:chad')
        end

        it 'annotation match is case insensetive' do
          expect(
            resolve_identity.call(
              account: 'rspec',
              identity: 'chad.example',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('rspec:user:chad')
                  allow(double).to receive(:resource?).and_return(true)
                  allow(double).to receive(:resource).and_return(
                    instance_double(::Resource).tap do |resource|
                      allow(resource).to receive(:annotation).with('authn-oidc/identity').and_return('Chad.Example')
                    end
                  )
                end
              ]
            ).id
          ).to eq('rspec:user:chad')
        end
      end

      context 'when multiple roles match' do
        let(:resource) do
          instance_double(::Resource).tap do |resource|
            allow(resource).to receive(:annotation).with('authn-oidc/identity').and_return('chad.example')
          end
        end
        it 'raises an error' do
          expect do
            resolve_identity.call(
              account: 'rspec',
              identity: 'chad.example',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('rspec:user:chad')
                  allow(double).to receive(:resource?).and_return(true)
                  allow(double).to receive(:resource).and_return(resource)
                end,
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('rspec:user:brad')
                  allow(double).to receive(:resource?).and_return(true)
                  allow(double).to receive(:resource).and_return(resource)
                end
              ]
            )
          end.to raise_error(
            Errors::Authentication::Security::MultipleRoleMatchesFound,
            /CONJ00009E 'chad.example' matched multiple roles/
          )
        end
      end

      context 'when the account does not match the role' do
        it 'raises the error RoleNotFound' do
          expect do
            resolve_identity.call(
              account: 'rspec',
              identity: 'chad.example',
              allowed_roles: [
                instance_double(::Role).tap do |double|
                  allow(double).to receive(:id).and_return('foo:user:chad')
                  allow(double).to receive(:resource?).and_return(true)
                  allow(double).to receive(:resource).and_return(
                    instance_double(::Resource).tap do |resource|
                      allow(resource).to receive(:annotation).with('authn-oidc/identity').and_return('chad.example')
                    end
                  )
                end
              ]
            )
          end.to raise_error(
            Errors::Authentication::Security::RoleNotFound,
            /CONJ00007E 'chad.example' not found/
          )
        end
      end
    end
  end
end
