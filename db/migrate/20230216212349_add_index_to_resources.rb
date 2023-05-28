# frozen_string_literal: true

Sequel.migration do
  up do
    execute <<-SQL
    CREATE INDEX resources_gin_trgm_idx ON resources(resource_id text_pattern_ops);
    SQL
    $$;
  end
  down do
    execute "DROP INDEX IF EXISTS resources_gin_trgm_idx"
  end
end
