# frozen_string_literal: true

Sequel.migration do
  up do
    execute Functions.ownership_trigger_sql
  end

  down do
  end
end
