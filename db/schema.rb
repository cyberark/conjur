Sequel.migration do
  change do
    create_table(:roles) do
      column :role_id, "text", :null=>false
      column :created_at, "timestamp without time zone", :default=>Sequel::LiteralString.new("transaction_timestamp()")
      
      primary_key [:role_id]
    end
    
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:secrets) do
      column :resource_id, "text", :null=>false
      column :counter, "integer", :null=>false
      column :value, "bytea", :null=>false
      
      primary_key [:resource_id, :counter]
    end
    
    create_table(:slosilo_keystore) do
      column :id, "text", :null=>false
      column :key, "bytea", :null=>false
      column :fingerprint, "text", :null=>false
      
      primary_key [:id]
      
      index [:fingerprint], :name=>:slosilo_keystore_fingerprint_key, :unique=>true
    end
    
    create_table(:credentials) do
      column :role_id, "text", :null=>false
      foreign_key :client_id, :roles, :type=>"text", :key=>[:role_id], :on_delete=>:cascade
      column :api_key, "bytea"
      column :encrypted_hash, "bytea"
      column :expiration, "timestamp without time zone"
      
      primary_key [:role_id]
    end
    
    create_table(:resources) do
      column :resource_id, "text", :null=>false
      foreign_key :owner_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      column :created_at, "timestamp without time zone", :default=>Sequel::LiteralString.new("transaction_timestamp()")
      
      primary_key [:resource_id]
    end
    
    create_table(:role_memberships) do
      foreign_key :role_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      foreign_key :member_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      foreign_key :grantor_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      column :admin_option, "boolean", :default=>false, :null=>false
      
      primary_key [:role_id, :member_id]
      
      index [:member_id], :name=>:role_memberships_member
    end
    
    create_table(:annotations) do
      foreign_key :resource_id, :resources, :type=>"text", :null=>false, :key=>[:resource_id], :on_delete=>:cascade
      column :name, "text", :null=>false
      column :value, "text", :null=>false
      
      primary_key [:resource_id, :name]
      
      index [:name]
    end
    
    create_table(:permissions) do
      column :privilege, "text", :null=>false
      column :grant_option, "boolean", :default=>false, :null=>false
      foreign_key :resource_id, :resources, :type=>"text", :null=>false, :key=>[:resource_id], :on_delete=>:cascade
      foreign_key :role_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      foreign_key :grantor_id, :roles, :type=>"text", :null=>false, :key=>[:role_id], :on_delete=>:cascade
      
      primary_key [:privilege, :resource_id, :role_id]
    end
  end
end
Sequel.migration do
  change do
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20121215032820_create_keystore.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628212347_create_roles.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628212349_create_resources.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628212358_create_role_memberships.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628212428_create_permissions.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628212433_create_annotations.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160628222441_create_credentials.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160630172059_create_secrets.rb')"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20160705141848_authz_functions.rb')"
  end
end
