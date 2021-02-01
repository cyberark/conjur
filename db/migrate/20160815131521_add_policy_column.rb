# frozen_string_literal: true

Sequel.migration do
  TABLES = %w[roles resources role_memberships permissions annotations]

  up do
    TABLES.each do |table|
      alter_table table.to_sym do
        add_foreign_key :policy_id, :resources, type: String, on_delete: :cascade
      end

      execute <<-SQL
      ALTER TABLE #{table}
      ADD CONSTRAINT verify_policy_kind CHECK (kind(policy_id) = 'policy')
      SQL
    end
  end

  down do
    TABLES.each do |table|
      execute %Q(ALTER TABLE #{table} DROP CONSTRAINT verify_policy_kind)
      alter_table table.to_sym do
        drop_column :policy_id
      end
    end
  end
end
