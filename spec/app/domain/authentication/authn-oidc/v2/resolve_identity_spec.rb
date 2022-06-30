# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(' Authentication::AuthnOidc::V2::ResolveIdentity') do

  let(:alice) { "rspec:user:alice" }
  let(:bob) { "rspec:user:bob" }
  let(:chad) { "rspec:user:chad" }

  let(:allowed_roles) do
    [user_alice, user_chad, user_dave, user_edward]
  end

  let(:user_alice) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:id).and_return(alice)
      allow(double).to receive(:resource?).and_return(true)
      allow(double).to receive(:resource).and_return(alice_resource)
    end
  end
  let(:user_dave) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:id).and_return(alice)
      allow(double).to receive(:resource?).and_return(true)
      allow(double).to receive(:resource).and_return(same_annotation)
    end
  end
  let(:user_edward) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:id).and_return(alice)
      allow(double).to receive(:resource?).and_return(true)
      allow(double).to receive(:resource).and_return(same_annotation)
    end
  end
  let(:user_chad) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:id).and_return(chad)
      allow(double).to receive(:resource?).and_return(true)
      allow(double).to receive(:resource).and_return(chad_resource)
    end
  end

  let(:chad_resource) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:annotation).with('authn-oidc/identity').and_return("chad.example")
    end
  end

  let(:same_annotation) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:annotation).with('authn-oidc/identity').and_return("bad.example")
    end
  end

  let(:alice_resource) do
    instance_double(::Resource).tap do |double|
      allow(double).to receive(:annotation).with('authn-oidc/identity').and_return("alice.example")
    end
  end

  let(:resolve_Identity) do
    Authentication::AuthnOidc::V2::ResolveIdentity.new()
  end

  describe('#call') do
    context 'when a role_id matches the identity exist' do
      it 'returns the role' do
        expect(resolve_Identity.call(account: 'rspec', identity: "alice", allowed_roles: allowed_roles).id)
          .to eq(alice)
      end
    end

    context 'when the identity does not match a role or annotation' do
      it 'raises the error RoleNotFound' do
        expect { resolve_Identity.call(account: 'rspec', identity: "bob", allowed_roles: allowed_roles) }
          .to raise_error(Errors::Authentication::Security::RoleNotFound, /CONJ00007E 'bob' not found/)
      end
    end

    context 'when the identity does not matches an annotation' do
      it 'returns the role of the user' do
        expect(resolve_Identity.call(account: 'rspec', identity: "chad.example", allowed_roles: allowed_roles).id)
          .to eq(chad)
      end
    end

    context 'when the identity matches an annotation, but multiple roles have the same annotation' do
      it 'raises the an error' do
        expect { resolve_Identity.call(account: 'rspec', identity: "bad.example", allowed_roles: allowed_roles) }
          .to raise_error("Multiple annotations match identity: bad.example")
      end
    end

  end
end

