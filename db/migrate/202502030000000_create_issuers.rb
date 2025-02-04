# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :issuers do
      String :issuer_id
      String :account
      String :issuer_type, null: false
      Integer :max_ttl, null: false
      column :data, "bytea"
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
      Timestamp :modified_at, null: false
      primary_key %i[account issuer_id], name: :issuer_pk
      foreign_key :policy_id, :resources, type: String, null: false, on_delete: :cascade
    end
  end
end
