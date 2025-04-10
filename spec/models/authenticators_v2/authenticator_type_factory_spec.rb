# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AuthenticatorTypeFactory, type: :model do
  let(:factory) { described_class.new }
  let(:authenticator_dict) do
    OpenStruct.new(
      type: "jwt",
      name: "auth1",
      branch: "authn-jwt",
      subtype: "other",
      enabled: true,
      owner: "rspec:policy:conjur/authn-jwt",
      annotations: { "name" => "description", "value" => "this is my jwt authenticator" },
      variables: {
        "rspec:variable:conjur/authn-jwt/auth1/ca-cert" => "CERT_DATA_1"
      }
    )
  end

  describe "#create_authenticator_type" do
    context "when type is 'jwt'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::JwtAuthenticatorType) }

      it "creates a JWT authenticator successfully" do
        expect(AuthenticatorsV2::JwtAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("jwt", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is 'aws'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AwsAuthenticatorType) }

      it "creates a AWS authenticator successfully" do
        expect(AuthenticatorsV2::AwsAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("aws", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is 'azure'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AzureAuthenticatorType) }

      it "creates a Azure authenticator successfully" do
        expect(AuthenticatorsV2::AzureAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("azure", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is 'gcp'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::GcpAuthenticatorType) }

      it "creates a Gcp authenticator successfully" do
        expect(AuthenticatorsV2::GcpAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("gcp", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is 'k8s'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::K8sAuthenticatorType) }

      it "creates a K8s authenticator successfully" do
        expect(AuthenticatorsV2::K8sAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("k8s", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is 'ldap'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::LdapAuthenticatorType) }

      it "creates a ldap authenticator successfully" do
        expect(AuthenticatorsV2::LdapAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type("ldap", authenticator_dict)
        expect(authenticator).to be(authenticator_instance)
      end
    end

    context "when type is unsupported" do
      it "raises an error for an unsupported type" do
        expect do
          factory.create_authenticator_type("unsupported", authenticator_dict)
        end.to raise_error(ApplicationController::UnprocessableEntity, "'unsupported' authenticators are not supported.")
      end
    end

    context "when type is nil" do
      it "raises an error for missing authenticator type" do
        expect do
          factory.create_authenticator_type(nil, authenticator_dict)
        end.to raise_error(ApplicationController::UnprocessableEntity, "Authenticator type is required")
      end
    end
  end
end
