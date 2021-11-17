# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :credentials do
      # Not an FK, because credentials won't be dropped when the RBAC is rebuilt
      String :role_id, primary_key: true

      foreign_key :client_id, :roles, type: String, null: true, on_delete: :cascade

      column :api_key, "bytea"
      column :encrypted_hash, "bytea"
      Timestamp :expiration
    end
  end
end
