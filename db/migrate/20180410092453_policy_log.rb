# frozen_string_literal: true

Sequel.migration do
  tables = %i[roles role_memberships resources permissions annotations]

  up do
    execute """
      CREATE TYPE policy_log_op AS ENUM ('INSERT', 'DELETE', 'UPDATE');
      CREATE TYPE policy_log_kind AS ENUM #{literal(tables.map(&:to_s))};
      CREATE EXTENSION IF NOT EXISTS hstore;
    """

    key = %i[policy_id version]
    create_table :policy_log do
      String :policy_id, null: false
      Integer :version, null: false
      foreign_key key, :policy_versions, on_delete: :cascade
      index key

      column :operation, :policy_log_op, null: false
      column :kind, :policy_log_kind, null: false
      column :subject, :hstore, null: false
      column :at, :timestamptz, null: false, default: Sequel.function(:clock_timestamp)
    end

    tables.each do |table|
      # find the primary key of the table
      primary_key = schema(table).select{|x,s|s[:primary_key]}.map(&:first).map(&:to_s).pg_array
      execute """
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
                slice(hstore(subject), #{literal(primary_key)})
              ;
            ELSE
              RAISE WARNING 'modifying data outside of policy load: %', subject.policy_id;
            END IF;
            RETURN subject;
          END;
        $$ LANGUAGE plpgsql
        SET search_path FROM CURRENT;

        CREATE TRIGGER policy_log
          AFTER INSERT OR UPDATE ON #{table}
          FOR EACH ROW
          WHEN (NEW.policy_id IS NOT NULL)
          EXECUTE PROCEDURE policy_log_#{table}();

        CREATE TRIGGER policy_log_d
          AFTER DELETE ON #{table}
          FOR EACH ROW
          WHEN (OLD.policy_id IS NOT NULL)
          EXECUTE PROCEDURE policy_log_#{table}();
      """
    end
  end

  down do
    tables.each do |table|
      execute """
        DROP TRIGGER policy_log ON #{table};
        DROP TRIGGER policy_log_d ON #{table};
        DROP FUNCTION policy_log_#{table}();
      """
    end

    drop_table :policy_log

    %w[op kind].each do |t|
      execute "DROP TYPE policy_log_#{t}"
    end
  end
end
