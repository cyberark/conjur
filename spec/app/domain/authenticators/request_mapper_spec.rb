require 'spec_helper'

describe Authenticators::RequestMapper do
  let(:account) {"rspec"}
  let(:type) {"jwt"}
  let(:data) do
    {
      "public_keys": { "test": "http://uri" },
      "issuer": "test",
      "identity": {
        "token_app_property": "prop",
        "enforced_claims": %w[test 123],
        "claim_aliases": { "myclaim": "myvalue", "second": "two" }
      }
    }
  end

  let(:request_body) do
    {
      "type": type,
      "name": "test-id",
      "owner": { "kind": "user", "id": "admin" },
      "enabled": false,
      "data": data,
      "annotations": {
        "test": "123"
      }
    }
  end

  let(:mapper) { described_class.new }

  describe "#call" do
    context "when a request body with an authenticator is recieve" do
      it 'returns a mapped auth hash' do
        expect(mapper.call(request_body, account).result).to eq(
          {
            "type": "authn-jwt",
            "account": "rspec",
            "service_id": "test-id",
            "owner_id": "rspec:user:admin",
            "enabled": false,
            "variables": {
              "public_keys": "{\"test\":\"http://uri\"}",
              "issuer": "test",
              "token_app_property": "prop",
              "enforced_claims": "test,123",
              "claim_aliases": "myclaim:myvalue,second:two"
            },
            "annotations": {
              "test": "123"
            }
          }
        )
      end
    end

    context "when a request body with an aws authenticator is recieve" do
      let(:type) {"aws"}
      let(:data) {nil}
      it 'returns a mapped auth hash' do
        expect(mapper.call(request_body, account).result).to eq(
          {
            "type": "authn-iam",
            "account": "rspec",
            "service_id": "test-id",
            "owner_id": "rspec:user:admin",
            "enabled": false,
            "variables": nil,
            "annotations": {
              "test": "123"
            }
          }
        )
      end
    end
  end
end
