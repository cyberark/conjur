# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :authenticator_configs do
      primary_key :id
      foreign_key :resource_id, :resources, type: String, null: false, unique: true, on_delete: :cascade
      TrueClass :enabled, default: false, null: false
    end
  end
end
