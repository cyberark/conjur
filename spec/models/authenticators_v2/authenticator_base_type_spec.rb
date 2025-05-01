# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AuthenticatorBaseType, type: :model do
  let(:account) { "rspec" }
  let(:default_args) {{ ca_cert: "CERT_DATA_1" }}
  let(:args) { default_args }

  let(:authenticator_dict) do
    {
      type: "base",
      service_id: "auth1",
      account: account,
      enabled: true,
      owner_id: "#{account}:policy:conjur/base",
      annotations: { description: "this is my base authenticator" },
      variables: args
    }
  end

  let(:authenticator) { described_class.new(authenticator_dict) }

  describe "#initialize" do
    it "initializes with correct attributes" do
      expect(authenticator.type).to eq("base")
      expect(authenticator.name).to eq("auth1")
      expect(authenticator.enabled).to be(true)
      expect(authenticator.owner).to eq("#{account}:policy:conjur/base")
      expect(authenticator.annotations).to eq({ description: "this is my base authenticator" })
      expect(authenticator.variables).to eq({ ca_cert: "CERT_DATA_1" })
    end
  end

  describe '.token_ttl', type: 'unit' do
    context 'with default initializer' do
      it { expect(authenticator.token_ttl).to eq(nil) }
    end
  end

  describe '.resource_id', type: 'unit' do
    context 'correctly renders' do
      it { expect(authenticator.resource_id).to eq('rspec:webservice:conjur/base/auth1') }
    end
  end

  describe "#to_h" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when all attributes are present (base type)" do
      let(:authenticator_dict) do
        {
          type: "base",
          service_id: "auth1",
          branch: "conjur/base",
          enabled: true,
          owner_id: "#{account}:policy:conjur/base",
          annotations: { description: "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "conjur/base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/base", kind: "policy" },
          annotations: { description: "this is my base authenticator" }
        }

        json = authenticator.to_h
        expect(json).to eq(expected_json)
      end
    end

    context "when all attributes are present (base type), and owner is host and enable false" do
      let(:authenticator_dict) do
        {
          type: "base",
          service_id: "auth1",
          branch: "conjur/base",
          enabled: false,
          owner_id: "#{account}:host:conjur/data/host457",
          annotations: { description: "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "conjur/base",
          name: "auth1",
          enabled: false,
          owner: { id: "conjur/data/host457", kind: "host" },
          annotations: { description: "this is my base authenticator" }
        }

        json = authenticator.to_h
        expect(json).to eq(expected_json)
      end
    end

    context "when all attributes are present (base type), and owner is group and enable false" do
      let(:authenticator_dict) do
        {
          type: "base",
          service_id: "auth1",
          branch: "conjur/base",
          enabled: false,
          owner_id: "#{account}:group:conjur/data/group123",
          annotations: { description: "this is my base authenticator" },
          variables: {
            "#{account}:variable:conjur/base/auth1/ca-cert" => "CERT_DATA_1"
          }
        }
      end

      it "returns the correct JSON structure" do
        expected_json = {
          type: "base",
          branch: "conjur/base",
          name: "auth1",
          enabled: false,
          owner: { id: "conjur/data/group123", kind: "group" },
          annotations: { description: "this is my base authenticator" }
        }

        json = authenticator.to_h
        expect(json).to eq(expected_json)
      end
    end

    context "when annotations are missing" do
      let(:authenticator_dict) do
        {
          type: "base",
          service_id: "auth1",
          branch: "conjur/base",
          enabled: true,
          owner_id: "#{account}:policy:conjur/base",
          annotations: nil,
          variables: {}
        }
      end

      it "returns JSON without the annotations key" do
        expected_json = {
          type: "base",
          branch: "conjur/base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/base", kind: "policy" }
        }

        json = authenticator.to_h
        expect(json).to eq(expected_json)
      end
    end

    context "when annotations are empty hash" do
      let(:authenticator_dict) do
        {
          type: "base",
          service_id: "auth1",
          branch: "conjur/base",
          enabled: true,
          owner_id: "#{account}:policy:conjur/base",
          annotations: "",
          variables: {}
        }
      end

      it "returns JSON without the annotations key" do
        expected_json = {
          type: "base",
          branch: "conjur/base",
          name: "auth1",
          enabled: true,
          owner: { id: "conjur/base", kind: "policy" }
        }

        json = authenticator.to_h
        expect(json).to eq(expected_json)
      end
    end
  end
end
