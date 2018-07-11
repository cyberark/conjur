# frozen_string_literal: true

Sequel.migration do
  change do
    create_table  :permissions do
      String :privilege, null: false
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      foreign_key :role_id, :roles, type: String, null: false, on_delete: :cascade
      
      primary_key [:privilege, :resource_id, :role_id]
    end
  end
end
