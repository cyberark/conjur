Sequel.migration do
  change do
    create_table :secrets do
      # Not an FK, because secrets won't be dropped when the RBAC is rebuilt
      primary_key :resource_id, type: String, null: false
      
      column :value, "bytea", null: false
    end
  end
end
