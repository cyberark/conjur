# frozen_string_literal: true

Sequel.migration do
  tables = %i[roles role_memberships resources permissions annotations]

  up do
    tables.each do |table|
      # find the primary key of the table
      primary_key_columns = schema(table).select{|_x, s| s[:primary_key]}.map(&:first).map(&:to_s).pg_array
      execute <<-SQL
        CREATE OR REPLACE FUNCTION policy_log_#{table}() RETURNS TRIGGER AS $$
          DECLARE
            subject #{table};
            current policy_versions;
            skip boolean;
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              subject := OLD;
            ELSE
              subject := NEW;
            END IF;

            BEGIN
                skip := current_setting('conjur.skip_insert_policy_log_trigger');
            EXCEPTION WHEN OTHERS THEN
                skip := false;
            END;

            IF skip THEN
              RETURN subject;
            END IF;

            current = current_policy_version();
            IF current.resource_id = subject.policy_id THEN
              INSERT INTO policy_log(
                policy_id, version,
                operation, kind,
                subject)
              SELECT
                (policy_log_record(
                    '#{table}',
                    #{literal(primary_key_columns)},
                    hstore(subject),
                    current.resource_id,
                    current.version,
                    TG_OP
                  )).*;
            END IF;
            RETURN subject;
          END;
        $$ LANGUAGE plpgsql
        SET search_path FROM CURRENT;
      SQL
    end
  end

  down do
    tables.each do |table|
      # find the primary key of the table
      primary_key_columns = schema(table).select{|_x, s| s[:primary_key]}.map(&:first).map(&:to_s).pg_array
      execute <<-SQL
        CREATE OR REPLACE FUNCTION policy_log_#{table}() RETURNS TRIGGER AS $$
          DECLARE
            subject #{table};
            current policy_versions;
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              subject := OLD;
            ELSE
              subject := NEW;
            END IF;
            current = current_policy_version();
            IF current.resource_id = subject.policy_id THEN
              INSERT INTO policy_log(
                policy_id, version,
                operation, kind,
                subject)
              SELECT
                current.resource_id, current.version,
                TG_OP::policy_log_op, '#{table}'::policy_log_kind,
                slice(hstore(subject), #{literal(primary_key_columns)})
              ;
            END IF;
            RETURN subject;
          END;
        $$ LANGUAGE plpgsql
        SET search_path FROM CURRENT;
      SQL


    end
  end
end
