# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::JwtAuthenticatorType, type: :model do
  include_context "create user"

  let(:account) { "rspec" }

  describe "#as_json - Data & Identity Sections" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    ## ✅ General Structure Tests
    context "when all data variables are missing" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { description: "this is my jwt authenticator" },
          variables: {} # No data variables
        }
      end

      it "includes the data key as an empty hash in json" do
        json = authenticator.to_h
        expected_json = {
          type: "jwt",
          name: "auth1",
          branch: "conjur/authn-jwt",
          enabled: true,
          owner: { id: "conjur/authn-jwt", kind: "policy" },
          annotations: { description: "this is my jwt authenticator" },
          data: {}
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when all identity variables are missing" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { description: "this is my jwt authenticator" },
          variables: {
            public_keys: "{\"type\": \"jwks\",\"value\": {\"keys\": [{\"e\": \"AQAB\", \"kid\": \"CNv0OI3RwqlHFEVnaoMAshCH2XE\",\"x5t\": \"CNv0OI3RwqlHFEVnaoMAshCH2XE\"}]}}",
            ca_cert: "CERT_DATA_1"
          } # No identity variables
        }
      end

      it "does not include identity key in json[:data]" do
        json = authenticator.to_h
        expected_json = {
          type: "jwt",
          name: "auth1",
          branch: "conjur/authn-jwt",
          enabled: true,
          owner: { id: "conjur/authn-jwt", kind: "policy" },
          annotations: { description: "this is my jwt authenticator" },
          data: {
            public_keys: { type: "jwks", value: { keys: [{ e: "AQAB", kid: "CNv0OI3RwqlHFEVnaoMAshCH2XE", x5t: "CNv0OI3RwqlHFEVnaoMAshCH2XE" }] } },
            ca_cert: "CERT_DATA_1"
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    ## Data Section Tests
    context "when extra unknown variables exist in data" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { description: "this is my jwt authenticator" },
          variables: {
            unknown_key: "random_value",
            ca_cert: "CERT_DATA_1"
          }
        }
      end

      it "ignores unknown keys and includes only valid ones" do
        json = authenticator.to_h
        expected_json = {
          type: "jwt",
          name: "auth1",
          branch: "conjur/authn-jwt",
          enabled: true,
          owner: { id: "conjur/authn-jwt", kind: "policy" },
          annotations: { description: "this is my jwt authenticator" },
          data: {
            ca_cert: "CERT_DATA_1"
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when different sets of variables exist" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { description: "this is my jwt authenticator" },
          variables: {
            ca_cert: "CERT_DATA_1",
            jwks_uri: "https://example.com/jwks",
            token_app_property: "app_property"
          }
        }
      end

      it "includes only provided variables" do
        json = authenticator.to_h
        expected_json = {
          type: "jwt",
          name: "auth1",
          branch: "conjur/authn-jwt",
          enabled: true,
          owner: { id: "conjur/authn-jwt", kind: "policy" },
          annotations: { description: "this is my jwt authenticator" },
          data: {
            ca_cert: "CERT_DATA_1",
            jwks_uri: "https://example.com/jwks",
            identity: {
              token_app_property: "app_property"
            }
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    ## Identity Section Tests
    context "when enforced-claims is an empty string" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { description: "this is my jwt authenticator" },
          variables: {
            enforced_claims: "" # Empty string
          }
        }
      end

      it "returns an empty array for enforced-claims" do
        json = authenticator.to_h
        expected_json = {
          type: "jwt",
          name: "auth1",
          branch: "conjur/authn-jwt",
          enabled: true,
          owner: { id: "conjur/authn-jwt", kind: "policy" },
          annotations: { description: "this is my jwt authenticator" },
          data: {
            identity: {
              enforced_claims: []
            }
          }
        }
        expect(json).to eq(expected_json)
      end
    end

    context "when claim-aliases is an empty string" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { name: "description", value: "this is my jwt authenticator" },
          variables: {
            claim_aliases: "" # ✅ Empty string
          }
        }
      end

      it "returns an empty hash for claim-aliases" do
        json = authenticator.to_h
        expect(json[:data][:identity][:claim_aliases]).to eq({})
      end
    end

    context "when enforced-claims contain duplicate values" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { name: "description", value: "this is my jwt authenticator" },
          variables: {
            enforced_claims: "sub,sub,exp,iss,exp"
          }
        }
      end

      it "returns a unique array of values" do
        json = authenticator.to_h
        expect(json[:data][:identity][:enforced_claims]).to match_array(%w[sub exp iss])
      end
    end

    context "when claim-aliases contain empty pairs" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { name: "description", value: "this is my jwt authenticator" },
          variables: {
            claim_aliases: "role:admin,group:devs,empty:"
          }
        }
      end

      it "removes empty pairs and includes only valid entries" do
        json = authenticator.to_h
        expect(json[:data][:identity][:claim_aliases]).to eq(
          {
            role: "admin",
            group: "devs"
          }
        )
      end
    end

    context "when claim-aliases contains string without pairs" do
      let(:authenticator_dict) do
        {
          type: "authn-jwt",
          service_id: "auth1",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-jwt",
          annotations: { name: "description", value: "this is my jwt authenticator" },
          variables: {
            claim_aliases: "role"
          }
        }
      end

      it "removes empty pairs and includes only valid entries" do
        json = authenticator.to_h
        expect(json[:data][:identity][:claim_aliases]).to eq({})
      end
    end
  end
end
