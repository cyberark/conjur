# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :host_factory_tokens do
      String :token_sha256, null: false, size: 64
      bytea :token, null: false
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      column :cidr, "cidr[]", null: false, default: "{}"
      timestamp :expiration
      
      primary_key [ :token_sha256 ]
    end
  end
end
