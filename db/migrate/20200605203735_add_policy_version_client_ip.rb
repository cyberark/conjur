Sequel.migration do
  change do
    alter_table :policy_versions do
      add_column :client_ip, String
    end
  end
end
