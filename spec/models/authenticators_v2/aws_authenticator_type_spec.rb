# frozen_string_literal: true

require 'spec_helper'

describe AuthenticatorsV2::AwsAuthenticatorType, type: :model do
  include_context "create user"

  let(:account) { "rspec" }

  describe "Get authenticator - AWS - #as_json" do
    let(:authenticator) { described_class.new(authenticator_dict) }

    context "when aws dictionary received" do
      let(:authenticator_dict) do
        {
          type: "authn-iam",
          service_id: "auth1",
          subtype: nil,
          enabled: true,
          owner_id: "#{account}:policy:conjur/authn-iam",
          annotations: { description: "this is my aws authenticator" },
          variables: {}
        }
      end

      it "does not include data attribute in the json" do
        json = authenticator.to_h
        expected_json = {
          type: "aws",
          name: "auth1",
          branch: "conjur/authn-iam",
          enabled: true,
          owner: { id: "conjur/authn-iam", kind: "policy" },
          annotations: { description: "this is my aws authenticator" }
        }
        expect(json).to eq(expected_json)
      end
    end
  end
end
