# frozen_string_literal: true

Sequel.migration do
  tables = %i[roles role_memberships resources permissions annotations]

  # This version of the trigger takes into consideration not only resources with id equal to the policy_id
  # but also resources that are further in the policies tree and belongs to the policy.
  # In practice, as hierarchy is built by the parts of id, 'LIKE' clause is added:
  #   IF current.resource_id = subject.policy_id OR subject.policy_id LIKE current.resource_id || '/%' THEN
  # instead of:
  #   IF current.resource_id = subject.policy_id THEN

  up do
    tables.each do |table|
      # find the primary key of the table
      primary_key_columns = schema(table).select{|_x, s| s[:primary_key]}.map(&:first).map(&:to_s).pg_array
      execute <<-SQL
        CREATE OR REPLACE FUNCTION current_policy_version_no_policy_text()
        RETURNS SETOF policy_versions
        SET search_path FROM CURRENT
        LANGUAGE sql STABLE AS $$
          SELECT resource_id, role_id, "version", created_at, NULL as policy_text, policy_sha256, finished_at, client_ip 
          FROM policy_versions WHERE finished_at IS NULL
        $$;
      SQL

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

            current = current_policy_version_no_policy_text();
            IF current.resource_id = subject.policy_id OR subject.policy_id LIKE current.resource_id || '/%' THEN
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
            ELSE
              RAISE WARNING 'modifying data outside of policy load: %', subject.policy_id;
            END IF;
            RETURN subject;
          END;
        $$ LANGUAGE plpgsql
        SET search_path FROM CURRENT;
      SQL
    end
  end
end
