Sequel.migration do
  change do
    alter_table :roles do
      add_column :api_key_enabled, "boolean", null: false, default: true
    end
  end
end
