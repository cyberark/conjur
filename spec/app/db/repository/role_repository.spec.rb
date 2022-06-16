# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::RoleRepository') do

  let(:alice) { "rspec:user:alice" }
  let(:bob) { "rspec:user:bob" }
  let(:chad) { "rspec:user:chad" }

  let(:role) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:[]).with(alice).and_return(user_alice)
      allow(double).to receive(:[]).with(bob).and_return(nil)
      allow(double).to receive(:[]).with("rspec:user:chad@sombody.com").and_return(nil)
      allow(double).to receive(:[]).with({:role_id=>chad}).and_return(user_chad)
    end
  end

  let(:user_alice) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:role_id).and_return(alice)
    end
  end

  let(:user_chad) do
    instance_double(::Role).tap do |double|
      allow(double).to receive(:role_id).and_return(chad)
    end
  end

  let(:annotated_user) do
    instance_double(::Annotation).tap do |double|
      allow(double).to receive(:resource_id).and_return(chad)
    end
  end

  let(:annotation) do
    class_double(::Annotation).tap do |double|
      allow(double).to receive(:find_annotation).with(anything()).and_return(annotated_user)
    end
  end

  let(:roles) do
    DB::Repository::RoleRepository.new(
      role: role,
      annotation: annotation,
    )
  end

  describe('#find') do
    context 'when resource_id exist' do
      it 'returns the role' do
        expect(roles.find(account: 'rspec', identifier: "alice").role_id)
          .to eq(alice)
      end
    end

    context 'when resource_id does not exist' do
      it 'returns nil' do
        expect(roles.find(account: 'rspec', identifier: "bob"))
          .to eq(nil)
      end
    end

    context 'when resource_id does not exist but the annotation does' do
      it 'returns the role of the user' do
        expect(roles.find(account: 'rspec', identifier: "chad@sombody.com", name: "authn-oidc/identity").role_id)
          .to eq(chad)
      end
    end
  end
end

