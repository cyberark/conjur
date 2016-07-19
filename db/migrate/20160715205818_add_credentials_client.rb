Sequel.migration do
  up do
    alter_table :credentials do
      add_foreign_key :client_id, :roles, type: String, null: true, on_delete: :cascade
    end
  end

  down do
    alter_table :credentials do
      drop_foreign_key :client_id
    end
  end
end
