# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :roles do
      String :role_id, primary_key: true
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
    end
  end
end
