# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :resources do
      String :resource_id, primary_key: true
      foreign_key :owner_id, :roles, type: String, null: false, on_delete: :cascade
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
    end
  end
end
