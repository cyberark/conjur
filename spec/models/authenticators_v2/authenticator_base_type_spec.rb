# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AuthenticatorBaseType, type: :model do
  let(:account) { "rspec" }

  describe "#initialize" do
    let(:authenticator_dict) do
      {
        type: "base",
        name: "auth1",
        branch: "authn-base",
        enabled: true,
        owner: "#{account}:policy:conjur/authn-base",
        annotations: { "description" => "this is my base authenticator" },
        variables: {
          "#{account}:variable:conjur/authn-base/auth1/ca-cert" => "CERT_DATA_1"
        }
      }
    end

    let(:authenticator) { described_class.new(authenticator_dict) }

    it "initializes with correct attributes" do
      expect(authenticator.type).to eq("base")
      expect(authenticator.name).to eq("auth1")
      expect(authenticator.branch).to eq("authn-base")
      expect(authenticator.enabled).to be(true)
      expect(authenticator.owner).to eq("#{account}:policy:conjur/authn-base")
      expect(authenticator.annotations).to eq({ "description" => "this is my base authenticator" })
      expect(authenticator.authenticator_variables).to eq({ "#{account}:variable:conjur/authn-base/auth1/ca-cert" => "CERT_DATA_1" })
    end
  end

  describe "#as_json" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when all attributes are present (base type)" do
      let(:authenticator_dict) do
        {
          type: "base",
          name: "auth1",
          branch: "authn-base",
          enabled: true,
          owner: "#{account}:policy:conjur/authn-base",
          annotations: { "description" => "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/authn-base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "authn-base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/authn-base", kind: "policy" },
          annotations: { "description" => "this is my base authenticator" }
        }

        json = authenticator.as_json
        expect(json).to eq(expected_json)
      end
    end

    context "when all attributes are present (base type), and owner is host and enable false" do
      let(:authenticator_dict) do
        {
          type: "base",
          name: "auth1",
          branch: "authn-base",
          enabled: false,
          owner: "#{account}:host:conjur/data/host457",
          annotations: { "description" => "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/authn-base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "authn-base",
          name: "auth1",
          enabled: false,
          owner: { id: "conjur/data/host457", kind: "host" },
          annotations: { "description" => "this is my base authenticator" }
        }

        json = authenticator.as_json
        expect(json).to eq(expected_json)
      end
    end

    context "when all attributes are present (base type), and owner is group and enable false" do
      let(:authenticator_dict) do
        {
          type: "base",
          name: "auth1",
          branch: "authn-base",
          enabled: false,
          owner: "#{account}:group:conjur/data/group123",
          annotations: { "description" => "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/authn-base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "authn-base",
          name: "auth1",
          enabled: false,
          owner: { id: "conjur/data/group123", kind: "group" },
          annotations: { "description" => "this is my base authenticator" }
        }

        json = authenticator.as_json
        expect(json).to eq(expected_json)
      end
    end

    context "when annotations are missing" do
      let(:authenticator_dict) do
        {
          type: "base",
          name: "auth1",
          branch: "authn-base",
          enabled: true,
          owner: "#{account}:policy:conjur/authn-base",
          annotations: nil,
          variables: {}
        }
      end

      it "returns JSON without the annotations key" do
        expected_json = {
          type: "base",
          branch: "authn-base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/authn-base", kind: "policy" }
        }

        json = authenticator.as_json
        expect(json).to eq(expected_json)
      end
    end

    context "when annotations are empty hash" do
      let(:authenticator_dict) do
        {
          type: "base",
          name: "auth1",
          branch: "authn-base",
          enabled: true,
          owner: "#{account}:policy:conjur/authn-base",
          annotations: {},
          variables: {}
        }
      end

      it "returns JSON without the annotations key" do
        expected_json = {
          type: "base",
          branch: "authn-base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/authn-base", kind: "policy" }
        }

        json = authenticator.as_json
        expect(json).to eq(expected_json)
      end
    end
  end
end
