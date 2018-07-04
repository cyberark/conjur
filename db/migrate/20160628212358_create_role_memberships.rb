# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :role_memberships do
      foreign_key :role_id, :roles, type: String, null: false, on_delete: :cascade
      foreign_key :member_id, :roles, type: String, null: false, on_delete: :cascade
      TrueClass :admin_option, default: false, null: false
      TrueClass :ownership, default: false, null: false
      
      primary_key [:role_id, :member_id, :ownership]
      
      index [:member_id], name: :role_memberships_member
    end
  end
end
