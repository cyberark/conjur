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

    create_table :host_factory_layers do
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      foreign_key :role_id, :roles, type: String, null: false, on_delete: :cascade
      foreign_key :policy_id, :resources, type: String, on_delete: :cascade

      primary_key [ :resource_id, :role_id ]
    end
  end
end
