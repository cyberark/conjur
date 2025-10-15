# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::K8sAuthenticatorType, type: :model do
  include_context "create user"

  let(:account) { "rspec" }

  describe "#as_json" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when all data variables are missing" do
      let(:authenticator_dict) do
        {
          type: "authn-k8s",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-k8s",
          annotations: { description: "this is my k8s authenticator" },
          variables: {} # No data variables
        }
      end

      it "includes the data key as an empty hash in json" do
        json = authenticator.to_h
        expected_json = {
          type: "k8s",
          name: "auth1",
          branch: "conjur/authn-k8s",
          enabled: true,
          owner: { id: "conjur/authn-k8s", kind: "policy" },
          annotations: { description: "this is my k8s authenticator" },
          data: {}
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when non-string type data is returned" do
      let(:authenticator_dict) do
        {
          type: "authn-k8s",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-k8s",
          annotations: { description: "this is my k8s authenticator" },
          variables: {
            "ca/cert": "some-data".bytes
          }
        }
      end

      it "returns unchanged data" do
        json = authenticator.to_h
        expected_json = {
          type: "k8s",
          name: "auth1",
          branch: "conjur/authn-k8s",
          enabled: true,
          owner: { id: "conjur/authn-k8s", kind: "policy" },
          annotations: { description: "this is my k8s authenticator" },
          data: {
            "ca/cert": "some-data".bytes
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when extra unknown variables exist in data" do
      let(:authenticator_dict) do
        {
          type: "authn-k8s",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-k8s",
          annotations: { description: "this is my k8s authenticator" },
          variables: {
            "unknown-key": "random_value",
            "ca/cert": "CERT_DATA_1"
          }
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "k8s",
          name: "auth1",
          branch: "conjur/authn-k8s",
          enabled: true,
          owner: { id: "conjur/authn-k8s", kind: "policy" },
          annotations: { description: "this is my k8s authenticator" },
          data: {
            "ca/cert": "CERT_DATA_1"
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "with all variables specified" do
      let(:authenticator_dict) do
        {
          type: "authn-k8s",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-k8s",
          annotations: { description: "this is my k8s authenticator" },
          variables: {
            "ca/key": "CERT_KEY",
            "ca/cert": "CERT_DATA_1",
            "kubernetes/ca_cert": "CERT_DATA_2",
            "kubernetes/api_url": "http://api",
            "kubernetes/service_account_token": "token"
          }
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "k8s",
          name: "auth1",
          branch: "conjur/authn-k8s",
          enabled: true,
          owner: { id: "conjur/authn-k8s", kind: "policy" },
          annotations: { description: "this is my k8s authenticator" },
          data: {
            "ca/cert": "CERT_DATA_1",
            "ca/key": "CERT_KEY",
            "kubernetes/ca_cert": "CERT_DATA_2",
            "kubernetes/api_url": "http://api",
            "kubernetes/service_account_token": "token"
          }
        }
        expect(json).to eq(expected_json)
      end
    end
  end
end
