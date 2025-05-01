# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::GcpAuthenticatorType, type: :model do
  include_context "create user"

  let(:account) { "rspec" }

  describe "Get authenticator - GCP - #as_json" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when gcp dictionary received" do
      let(:authenticator_dict) do
        {
          type: "authn-gcp",
          service_id: "default",
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-gcp",
          annotations: { description: "this is my gcp authenticator" },
          variables: {}
        }
      end

      it "does not include data attribute in the json" do
        json = authenticator.to_h
        expected_json = {
          type: "gcp",
          name: "default",
          branch: "conjur/authn-gcp",
          enabled: true,
          owner: { id: "conjur/authn-gcp", kind: "policy" },
          annotations: { description: "this is my gcp authenticator" }
        }
        expect(json).to eq(expected_json)
      end
    end
  end
end
