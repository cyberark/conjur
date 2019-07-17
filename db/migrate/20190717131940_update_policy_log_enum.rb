# frozen_string_literal: true

Sequel.migration do
  # ALTER TYPE ... ADD VALUE.. cannot run in a transaction block
  no_transaction

  up do
    execute <<-SQL
    -- Add new table to policy log types
    ALTER TYPE policy_log_kind ADD VALUE IF NOT EXISTS 'policy_factories';
    SQL
  end
end
