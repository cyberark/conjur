# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :secrets do
      # Not an FK, because secrets won't be dropped when the RBAC is rebuilt
      String :resource_id, null: false
      Integer :version, null: false
      
      column :value, "bytea", null: false
      
      primary_key [ :resource_id, :version ]
    end

    execute Functions.create_version_trigger_sql(:secrets)
  end
  
  down do
    execute Functions.drop_version_trigger_sql(:secrets)

    drop_table :secrets
  end
end
