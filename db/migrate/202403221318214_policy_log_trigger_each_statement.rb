# frozen_string_literal: true

Sequel.migration do
  tables = %i[roles role_memberships resources permissions annotations]

  up do
    tables.each do |table|
      # find the primary key of the table
      primary_key_columns = schema(table).select{|_x, s| s[:primary_key]}.map(&:first).map(&:to_s).pg_array

      execute """
        CREATE OR REPLACE FUNCTION policy_log_#{table}() RETURNS TRIGGER AS $$
          DECLARE
            current policy_versions;
          BEGIN
            current = current_policy_version_no_policy_text();
            IF TG_OP = 'DELETE' THEN
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
                  )).*
              FROM old_table AS subject
              WHERE current.resource_id = subject.policy_id OR subject.policy_id LIKE current.resource_id || '/%';
            ELSE
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
                  )).*
              FROM new_table AS subject
              WHERE current.resource_id = subject.policy_id OR subject.policy_id LIKE current.resource_id || '/%';
            END IF;
            RETURN NULL;
          END;
        $$ LANGUAGE plpgsql
        SET search_path FROM CURRENT;

        CREATE OR REPLACE TRIGGER policy_log
          AFTER INSERT ON #{table}
          REFERENCING NEW TABLE AS new_table
          FOR EACH STATEMENT
          EXECUTE PROCEDURE policy_log_#{table}();

        CREATE OR REPLACE TRIGGER policy_log_u
          AFTER UPDATE ON #{table}
          REFERENCING NEW TABLE AS new_table
          FOR EACH STATEMENT
          EXECUTE PROCEDURE policy_log_#{table}();

        CREATE OR REPLACE TRIGGER policy_log_d
          AFTER DELETE ON #{table}
          REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE PROCEDURE policy_log_#{table}();
      """
    end
  end
end
