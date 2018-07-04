# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :secrets do
      add_column :expires_at, DateTime
    end
  end
end
