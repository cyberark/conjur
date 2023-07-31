# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :platforms do
      String :platform_id
      String :account
      String :platform_type, null: false
      Integer :max_ttl, null: false
      column :data, "bytea"
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
      Timestamp :modified_at, null: false
      primary_key [:account, :platform_id], name: :platforms_pk
      foreign_key :policy_id, :resources, type: String, null: false, on_delete: :cascade
    end
  end
end
