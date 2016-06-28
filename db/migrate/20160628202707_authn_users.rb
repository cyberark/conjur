Sequel.migration do
  change do
    Sequel::Model.db.create_schema :authn, if_not_exists: true
    
    create_table(:authn__users) do
      column :login, "text", :null=>false
      column :api_key, "bytea"
      column :encrypted_hash, "bytea"
      
      primary_key [:login]
    end
  end
end
