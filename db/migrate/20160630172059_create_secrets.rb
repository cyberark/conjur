Sequel.migration do
  up do
    execute "CREATE SEQUENCE secrets_seq START 1"
    
    create_table :secrets do
      # Not an FK, because secrets won't be dropped when the RBAC is rebuilt
      String :resource_id, null: false
      Integer :counter, null: false, default: ::Sequel.function(:nextval, 'secrets_seq')
      
      column :value, "bytea", null: false
      
      primary_key [ :resource_id, :counter ]
    end
  end
  
  down do
    drop_table :secrets
    execute "DROP SEQUENCE IF EXISTS secrets_seq"
  end
end
