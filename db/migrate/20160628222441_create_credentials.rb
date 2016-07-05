Sequel.migration do
  change do
    create_table :credentials do
      # Not an FK, because credentials won't be dropped when the RBAC is rebuilt
      primary_key :role_id, type: String, null: false

      column :api_key, "bytea"
      column :encrypted_hash, "bytea"
    end
  end
end
