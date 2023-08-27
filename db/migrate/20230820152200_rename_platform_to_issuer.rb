# frozen_string_literal: true

Sequel.migration do
  change do
    # Rename the table from :platforms to :issuers
    rename_table(:platforms, :issuers)

    alter_table(:issuers) do
      rename_column(:platform_id, :issuer_id)
      rename_column(:platform_type, :issuer_type)

      drop_constraint(:platforms_pk)
      add_primary_key [:account, :issuer_id], name: :issuers_pk
      drop_foreign_key(:policy_id)
      add_foreign_key(:policy_id, :resources, type: String, null: false, on_delete: :cascade)
    end
  end
end
