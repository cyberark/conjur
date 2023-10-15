# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :locks do
      String :lock_id
      String :account
      String :owner
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
      Timestamp :modified_at, null: false
      Timestamp :expires_at, null: false
      primary_key [:account, :lock_id], name: :locks_pk
    end
  end
end