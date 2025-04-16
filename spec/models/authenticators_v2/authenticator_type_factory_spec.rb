# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AuthenticatorTypeFactory, type: :model do
  let(:factory) { described_class.new }
  let(:type) { "jwt" }
  let(:authenticator_dict) do
    OpenStruct.new(
      type: "authn-#{type}",
      service_id: "auth1",
      enabled: true,
      owner_id: "rspec:policy:conjur/base",
      annotations: `{ "name": "description", "value": "this is my #{type} authenticator" }`,
      variables: {
        "rspec:variable:conjur/authn-#{type}/auth1/ca-cert" => "CERT_DATA_1"
      }
    )
  end

  describe "#create_authenticator_type" do
    context "when type is 'jwt'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::JwtAuthenticatorType) }

      it "creates a JWT authenticator successfully" do
        expect(AuthenticatorsV2::JwtAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'aws'" do
      let(:type) { "iam" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AwsAuthenticatorType) }

      it "creates a AWS authenticator successfully" do
        expect(AuthenticatorsV2::AwsAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'azure'" do
      let(:type) { "azure" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AzureAuthenticatorType) }

      it "creates a Azure authenticator successfully" do
        expect(AuthenticatorsV2::AzureAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'gcp'" do
      let(:type) { "gcp" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::GcpAuthenticatorType) }

      it "creates a Gcp authenticator successfully" do
        expect(AuthenticatorsV2::GcpAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'k8s'" do
      let(:type) { "k8s" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::K8sAuthenticatorType) }

      it "creates a K8s authenticator successfully" do
        expect(AuthenticatorsV2::K8sAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'ldap'" do
      let(:type) { "ldap" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::LdapAuthenticatorType) }

      it "creates a ldap authenticator successfully" do
        expect(AuthenticatorsV2::LdapAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is unsupported" do
      let(:type) { "test" }
      it "raises an error for an unsupported type" do
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.success?).to be(false)
        expect(authenticator.exception).to be(ApplicationController::UnprocessableEntity)
        expect(authenticator.status).to eq(:unprocessable_entity)
      end
    end

    context "when type is nil" do
      let(:authenticator_dict) do
        {
          service_id: "auth1",
          enabled: true,
          owner_id: "rspec:policy:conjur/base",
          variables: ""
        }
      end

      it "raises an error for missing authenticator type" do
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.success?).to be(false)
        expect(authenticator.exception).to be(ApplicationController::UnprocessableEntity)
        expect(authenticator.status).to eq(:unprocessable_entity)
      end
    end
  end
end
