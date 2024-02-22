require 'spec_helper'

include PermissionsHandler

describe "Permissions input validation" do
  let(:allowed_privilege) do
    %w[read execute update]
  end
  before do
    StaticAccount.set_account("rspec")
    allow(Resource).to receive(:[]).with("rspec:user:alice").and_return("resoruce")
    $primary_schema = "public"
  end
  context "when permission doesn't have subject" do
    it "input validation fails" do
      permissions = [
        {
          "privileges": [ "read" ]
        }
      ]
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when permission subject doesn't have kind" do
    it "input validation fails" do
      permissions = [
        {
          "subject": {
            "id": "alice"
          },
          "privileges": [ "read" ]
        }
      ]
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when permission there is no subject id" do
    it "input validation fails" do
      permissions = [
        {
          "subject": {
            "kind": "user"
          },
          "privileges": [ "read" ]
        }
      ]
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when permission subject kind is not supported" do
    it "input validation fails" do
      permissions = [
        {
          "subject": {
            "kind": "workload",
            "id": "alice"
          },
          "privileges": [ "read" ]
        }
      ]
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterValueInvalid)
    end
  end
  context "when subject resource doesn't exists" do
    let(:permissions) do
      [
        {
          "subject": {
            "kind": "user",
            "id": "alice"
          },
          "privileges": [ "read" ]
        }
      ]
    end
    before do
      allow(Resource).to receive(:[]).with("rspec:user:alice").and_return(nil)
      $primary_schema = "public"
    end
    it "input validation fails" do
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Exceptions::RecordNotFound)
    end
  end
  context "when there is no privileges" do
    let(:permissions) do
      [
        {
          "subject": {
            "kind": "user",
            "id": "alice"
          }
        }
      ]
    end
    it "input validation fails" do
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterMissing)
    end
  end
  context "when there privilege is not allowed" do
    let(:permissions) do
      [
        {
          "subject": {
            "kind": "user",
            "id": "alice"
          },
          "privileges": ["read", "write"]
        }
      ]
    end
    it "input validation fails" do
      expect { validate_permissions(permissions, allowed_privilege)
      }.to raise_error(Errors::Conjur::ParameterValueInvalid)
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
      resources_privileges = validate_permissions(permissions, allowed_privilege)
      expect(resources_privileges.size).to eq(1)
      expect(resources_privileges["rspec:user:alice"]).to eq(["read", "update"])
    end
  end
end