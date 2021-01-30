# frozen_string_literal: true

Sequel.migration do
  up do
    execute <<-SQL
    CREATE OR REPLACE FUNCTION account(id text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT CASE 
       WHEN split_part($1, ':', 1) = '' THEN NULL 
      ELSE split_part($1, ':', 1)
    END
    $$;

    CREATE OR REPLACE FUNCTION kind(id text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT CASE 
       WHEN split_part($1, ':', 2) = '' THEN NULL 
      ELSE split_part($1, ':', 2)
    END
    $$;

    CREATE OR REPLACE FUNCTION identifier(id text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT SUBSTRING($1 from '[^:]+:[^:]+:(.*)');
    $$;
    SQL

    # Create 'account', 'kind', and 'identifier' functions on roles and resources
    # Index 'account' and 'kind' functions on the 'roles' and 'resources' tables 
    # Index 'account,kind' on 'roles' and 'resources'
    # Require account, kind NOT NULL
    %w[roles resources].each do |table|
      primary_key = Sequel::Model(table.to_sym).primary_key

      execute <<-SQL
      CREATE OR REPLACE FUNCTION identifier(record #{table}) RETURNS text
      LANGUAGE sql IMMUTABLE
      AS $$
      SELECT identifier(record.#{primary_key})
      $$;
      SQL

      %w[account kind].each do |func|
        execute <<-SQL
        CREATE OR REPLACE FUNCTION #{func}(record #{table}) RETURNS text
        LANGUAGE sql IMMUTABLE
        AS $$
        SELECT #{func}(record.#{primary_key})
        $$;
        SQL

        execute "CREATE INDEX #{table}_#{func}_idx ON #{table}(#{func}(#{primary_key}))"

        execute <<-SQL
        ALTER TABLE #{table}
        ADD CONSTRAINT has_#{func} CHECK (#{func}(#{primary_key}) IS NOT NULL)
        SQL
      end
 
       execute <<-SQL
       CREATE INDEX #{table}_account_kind_idx 
       ON #{table}(account(#{primary_key}), kind(#{primary_key}))
       SQL
    end

    execute <<-SQL
    CREATE INDEX secrets_account_kind_identifier_idx ON secrets(account(resource_id), kind(resource_id), identifier(resource_id) text_pattern_ops);
    SQL
  end

  down do
    execute "DROP INDEX IF EXISTS secrets_account_kind_identifier_idx"

    %w[roles resources].each do |t|
      execute "DROP FUNCTION IF EXISTS identifier(#{t})"
      %w[account kind].each do |f|
        execute "DROP FUNCTION IF EXISTS #{f}(#{t})"
        execute "DROP INDEX #{t}_#{f}_idx"
        execute "ALTER TABLE #{t} DROP CONSTRAINT has_#{f}"
      end
      execute "DROP INDEX #{t}_account_kind_idx"
    end

    execute <<-SQL
    DROP FUNCTION IF EXISTS identifier(text);
    DROP FUNCTION IF EXISTS kind(text);
    DROP FUNCTION IF EXISTS account(text);
    SQL
  end
end
