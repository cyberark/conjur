Sequel.migration do
  up do
    create_table :secrets do
      # Not an FK, because secrets won't be dropped when the RBAC is rebuilt
      String :resource_id, null: false
      Integer :counter, null: false
      
      column :value, "bytea", null: false
      
      primary_key [ :resource_id, :counter ]
    end

    execute <<-COUNTER_TRIGGER
    CREATE OR REPLACE FUNCTION secrets_next_counter() RETURNS TRIGGER
      LANGUAGE plpgsql STABLE STRICT
    AS $$
    DECLARE
      next_counter integer;
    BEGIN
      SELECT coalesce(max(counter), 0) + 1 INTO next_counter
        FROM secrets 
        WHERE resource_id = NEW.resource_id;

      NEW.counter = next_counter;
      RETURN NEW;
    END
    $$;

    CREATE TRIGGER secrets_counter
    BEFORE INSERT
    ON secrets
    FOR EACH ROW
    EXECUTE PROCEDURE secrets_next_counter();
    COUNTER_TRIGGER
  end
  
  down do
    execute "DROP TRIGGER IF EXISTS secrets_counter ON secrets"
    execute "DROP FUNCTION IF EXISTS secrets_next_counter()"
    drop_table :secrets
  end
end
