# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::PersistAuthFactory) do
  let(:k8s_data) { Authentication::AuthnK8s::AuthenticatorData }
  let(:azure_data) { Authentication::AuthnAzure::AuthenticatorData }
  let(:oidc_data) { Authentication::AuthnOidc::AuthenticatorData }

  let(:k8s_initializer) { Authentication::AuthnK8s::InitializeK8sAuth }
  let(:k8s_initializer_instance) { instance_double(Authentication::AuthnK8s::InitializeK8sAuth) }
  let(:default_initializer) { Authentication::Default::InitializeDefaultAuth }
  let(:default_initializer_instance) { instance_double(Authentication::Default::InitializeDefaultAuth) }

  let(:persist_auth_class) { Authentication::PersistAuth }
  let(:persist_auth_instance) { instance_double(Authentication::PersistAuth) }

  subject do
    Authentication::PersistAuthFactory.new_from_authenticator(authenticator)
  end

  context "Given we attempt to create from an unsupported authenticator" do
    let(:authenticator) { "authn-jwt" }

    it "raises an ArgumentError" do
      expect{ subject }.to raise_error(ArgumentError)
    end
  end

  context "Given we attempt to create from a valid authenticator" do
    context "with the k8s authenticator" do
      let(:authenticator) { "authn-k8s" }

      it "uses the correct data class and initializer" do
        expect(k8s_initializer).to receive(:new).and_return(k8s_initializer_instance)

        expect(persist_auth_class).to receive(:new).with(
          auth_initializer: k8s_initializer_instance,
          auth_data_class: k8s_data
        ).and_return(persist_auth_instance)

        expect(subject).to eq(persist_auth_instance)
      end
    end

    context "with the azure authenticator" do
      let(:authenticator) { "authn-azure" }

      it "uses the correct data class and initializer" do
        expect(default_initializer).to receive(:new).and_return(default_initializer_instance)

        expect(persist_auth_class).to receive(:new).with(
          auth_initializer: default_initializer_instance,
          auth_data_class: azure_data
        ).and_return(persist_auth_instance)

        expect(subject).to eq(persist_auth_instance)
      end
    end

    context "with the oidc authenticator" do
      let(:authenticator) { "authn-oidc" }

      it "uses the correct data class and initializer" do
        expect(default_initializer).to receive(:new).and_return(default_initializer_instance)

        expect(persist_auth_class).to receive(:new).with(
          auth_initializer: default_initializer_instance,
          auth_data_class: oidc_data
        ).and_return(persist_auth_instance)

        expect(subject).to eq(persist_auth_instance)
      end
    end

  end
  
end
