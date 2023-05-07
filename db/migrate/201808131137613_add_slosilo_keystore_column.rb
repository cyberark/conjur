Sequel.migration do
  change do
    alter_table :slosilo_keystore do
      add_column :is_host, String
    end
  end
end


