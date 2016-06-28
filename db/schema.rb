Sequel.migration do
  change do
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:slosilo_keystore) do
      column :id, "text", :null=>false
      column :key, "bytea", :null=>false
      column :fingerprint, "text", :null=>false
      
      primary_key [:id]
      
      index [:fingerprint], :name=>:slosilo_keystore_fingerprint_key, :unique=>true
    end
  end
end
Sequel.migration do
  change do
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628202707_authn_users.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20121215032820_create_keystore.rb')"
  end
end
