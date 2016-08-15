class Functions
  class << self
    def create_version_trigger_sql(table)
      <<-COUNTER_TRIGGER
        CREATE OR REPLACE FUNCTION #{table}_next_version() RETURNS TRIGGER
          LANGUAGE plpgsql STABLE STRICT
        AS $$
        DECLARE
          next_version integer;
        BEGIN
          SELECT coalesce(max(version), 0) + 1 INTO next_version
            FROM #{table} 
            WHERE resource_id = NEW.resource_id;

          NEW.version = next_version;
          RETURN NEW;
        END
        $$;

        CREATE TRIGGER #{table}_version
        BEFORE INSERT
        ON #{table}
        FOR EACH ROW
        EXECUTE PROCEDURE #{table}_next_version();
      COUNTER_TRIGGER
    end

    def drop_version_trigger_sql(table)
      <<-COUNTER_TRIGGER
        DROP TRIGGER IF EXISTS #{table}_version ON #{table};
        DROP FUNCTION IF EXISTS #{table}_next_version();
      COUNTER_TRIGGER
    end
  end
end
