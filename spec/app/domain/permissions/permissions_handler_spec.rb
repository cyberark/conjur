require 'spec_helper'

describe "Permissions input validation" do
  let(:allowed_privilege) do
    %w[read execute update]
  end
  let(:allowed_kind) do
    %w[user host group]
  end
  let(:permissions_handler) do
    my_instance = Object.new
    my_instance.extend(PermissionsHandler)
    my_instance
  end

  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:user:alice").and_return("resoruce")
    $primary_schema = "public"
  end

  context "when validating permissions" do
    it "correct validators are being called for each field" do
      permissions = [
        {
          "subject": {
            "kind": "user",
            "id": "alice"
          },
          "privileges": [ "read" ]
        }
      ]

      expect(permissions_handler).to receive(:validate_field_required).with(:kind,{type: String,value: "user"})
      expect(permissions_handler).to receive(:validate_field_type).with(:kind,{type: String,value: "user"})
      expect(permissions_handler).to receive(:validate_resource_kind).with("user","alice",["user", "host", "group"])

      expect(permissions_handler).to receive(:validate_field_required).with(:id,{type: String,value: "alice"})
      expect(permissions_handler).to receive(:validate_field_type).with(:id,{type: String,value: "alice"})
      expect(permissions_handler).to receive(:validate_resource_id).with(:id,{type: String,value: "alice"})

      expect(permissions_handler).to receive(:validate_field_required).with(:privileges,{type: String,value: ["read"]})
      expect(permissions_handler).to receive(:validate_privilege).with("alice",[ "read" ], allowed_privilege)

      permissions_handler.validate_permissions(permissions, allowed_privilege)
    end
  end
  context "Input is valid" do
    let(:permissions) do
      [
        {
          "subject": {
            "kind": "user",
            "id": "alice"
          },
          "privileges": ["read", "update"]
        }
      ]
    end
    it "privileges object is created" do
      resources_privileges = permissions_handler.validate_permissions(permissions, allowed_privilege)
      expect(resources_privileges.size).to eq(1)
      expect(resources_privileges["rspec:user:alice"]).to eq(["read", "update"])
    end
  end
end