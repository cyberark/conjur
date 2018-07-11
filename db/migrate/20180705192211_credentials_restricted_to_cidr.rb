# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :credentials do
      add_column :restricted_to, "cidr[]", null: false, default: "{}"
    end
  end
end
