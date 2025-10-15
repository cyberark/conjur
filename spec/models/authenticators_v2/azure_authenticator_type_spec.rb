# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AzureAuthenticatorType, type: :model do
  include_context "create user"

  let(:account) { "rspec" }

  describe "#as_json - Data Section" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    ## ✅ General Structure Tests
    context "when all data variables are missing" do
      let(:authenticator_dict) do
        {
          type: "authn-azure",
          service_id: "auth1",
          subtype: nil,
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-azure",
          annotations: { description: "this is my azure authenticator" },
          variables: {} # No data variables
        }
      end

      it "includes the data key as an empty hash in json" do
        json = authenticator.to_h
        expected_json = {
          type: "azure",
          name: "auth1",
          branch: "conjur/authn-azure",
          enabled: true,
          owner: { id: "conjur/authn-azure", kind: "policy" },
          annotations: { description: "this is my azure authenticator" },
          data: {}
        }
        expect(json).to eq(expected_json)
      end
    end

    ## Data Section Tests
    context "when extra unknown variables exist in data" do
      let(:authenticator_dict) do
        {
          type: "authn-azure",
          service_id: "auth1",
          subtype: nil,
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-azure",
          annotations: { description: "this is my azure authenticator" },
          variables: {
            "unknown-key" => "random_value",
            provider_uri: "https://provider-uri"
          }
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "azure",
          name: "auth1",
          branch: "conjur/authn-azure",
          enabled: true,
          owner: { id: "conjur/authn-azure", kind: "policy" },
          annotations: { description: "this is my azure authenticator" },
          data: {
            provider_uri: "https://provider-uri"
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when only the valid variable exist" do
      let(:authenticator_dict) do
        {
          type: "authn-azure",
          service_id: "auth1",
          subtype: nil,
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-azure",
          annotations: { description: "this is my azure authenticator" },
          variables: {
            provider_uri: "https://provider-uri"
          }
        }
      end

      it "includes only provider uri" do
        json = authenticator.to_h
        expected_json = {
          type: "azure",
          name: "auth1",
          branch: "conjur/authn-azure",
          enabled: true,
          owner: { id: "conjur/authn-azure", kind: "policy" },
          annotations: { description: "this is my azure authenticator" },
          data: {
            provider_uri: "https://provider-uri"
          }
        }
        expect(json).to eq(expected_json)
      end
    end
  end
end
