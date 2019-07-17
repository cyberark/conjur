# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :policy_factories do |t|
      foreign_key :role_id, :roles, type: String, primary_key: true, null: false, on_delete: :cascade
      foreign_key :policy_id, :resources, type: String, on_delete: :cascade

      # Can't delete policy if there is a policy factory writing to it
      foreign_key :base_policy_id, :resources, type: String, on_delete: :restrict    

      t.text :template
    end

    primary_key_columns = schema(:policy_factories).select{|x,s|s[:primary_key]}.map(&:first).map(&:to_s).pg_array

    execute <<-SQL
    ALTER TABLE policy_factories
      ADD CONSTRAINT verify_policy_kind CHECK (kind(policy_id) = 'policy');

    ALTER TABLE policy_factories
      ADD CONSTRAINT verify_base_policy_kind CHECK (kind(base_policy_id) = 'policy');

    CREATE OR REPLACE FUNCTION policy_log_policy_factories() RETURNS TRIGGER AS $$
         DECLARE
           subject policy_factories;
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
                   'policy_factories',
                   #{literal primary_key_columns},
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

       CREATE TRIGGER policy_log
         AFTER INSERT OR UPDATE ON policy_factories
         FOR EACH ROW
         WHEN (NEW.policy_id IS NOT NULL)
         EXECUTE PROCEDURE policy_log_policy_factories();

       CREATE TRIGGER policy_log_d
         AFTER DELETE ON policy_factories
         FOR EACH ROW
         WHEN (OLD.policy_id IS NOT NULL)
         EXECUTE PROCEDURE policy_log_policy_factories();

      
    
    SQL
  end

  down do
    execute """
        DROP TRIGGER policy_log ON policy_factories;
        DROP TRIGGER policy_log_d ON policy_factories;
        DROP FUNCTION policy_log_policy_factories();
      """

    drop_table(:policy_factories)
  end
end
