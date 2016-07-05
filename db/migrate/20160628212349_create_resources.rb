Sequel.migration do
  change do
    create_table :resources do
      String :id, primary_key: true
      foreign_key :owner_id, :roles, type: String, null: false, on_delete: :cascade
    end
  end
end
