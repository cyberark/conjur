Sequel.migration do
  up do
    alter_table :credentials do
      add_column :expiration, :timestamp
    end
  end

  down do
    alter_table :credentials do
      drop_column :expiration
    end
  end
end
