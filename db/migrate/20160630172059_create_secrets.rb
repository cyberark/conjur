Sequel.migration do
  up do
    create_table :secrets do
      # Not an FK, because secrets won't be dropped when the RBAC is rebuilt
      String :resource_id, null: false
      Integer :counter, null: false
      
      column :value, "bytea", null: false
      
      primary_key [ :resource_id, :counter ]
    end
  end
  
  down do
    drop_table :secrets
  end
end
