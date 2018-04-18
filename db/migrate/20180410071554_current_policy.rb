Sequel.migration do
  up do
    alter_table :policy_versions do
      set_column_type :created_at, :timestamptz

      # timestamp of when the policy has finished loading
      # if NULL, the policy load hasn't been finalized yet
      add_column :finished_at, :timestamptz,
        index: true, # to quickly find the null
        null: true # will be enforced by a trigger
      add_constraint(:created_before_finish) { created_at <= finished_at }
    end

    execute """
      CREATE OR REPLACE FUNCTION policy_versions_finish()
        RETURNS trigger
      LANGUAGE plpgsql AS $$
        BEGIN
          UPDATE policy_versions pv
            SET finished_at = clock_timestamp()
            WHERE finished_at IS NULL;
          RETURN new;
        END;
      $$;

      -- deferred constraint trigger will run on transaction commit
      CREATE CONSTRAINT TRIGGER finish_current
        AFTER INSERT ON policy_versions
        INITIALLY DEFERRED
        FOR EACH ROW
        WHEN (NEW.finished_at IS NULL)
        EXECUTE PROCEDURE policy_versions_finish();

      -- if any version is current while creating new one, finalize it
      CREATE TRIGGER only_one_current
        BEFORE INSERT ON policy_versions
        FOR EACH ROW
        EXECUTE PROCEDURE policy_versions_finish();

      CREATE FUNCTION current_policy_version()
        RETURNS SETOF policy_versions
        SET search_path FROM CURRENT
        LANGUAGE sql STABLE AS $$
          SELECT * FROM policy_versions WHERE finished_at IS NULL $$;
    """
  end

  down do
    execute """
      DROP FUNCTION current_policy_version();
      DROP TRIGGER finish_current ON policy_versions;
      DROP TRIGGER only_one_current ON policy_versions;
      DROP FUNCTION policy_versions_finish();
    """

    alter_table :policy_versions do
      drop_column :finished_at
      set_column_type :created_at, :timestamp
    end
  end
end
