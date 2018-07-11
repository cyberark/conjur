# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :policy_versions do
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      foreign_key :role_id, :roles, type: String, null: false, on_delete: :cascade
      Integer :version, null: false
      Timestamp :created_at, null: false, default: Sequel.function(:transaction_timestamp)
      String :policy_text, null: false
      String :policy_sha256, null: false

      primary_key [:resource_id, :version]
    end

    execute Functions.create_version_trigger_sql(:policy_versions)
  end

  down do
    execute Functions.drop_version_trigger_sql(:policy_versions)
    
    drop_table :policy_versions
  end
end
