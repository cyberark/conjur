# frozen_string_literal: true

Sequel.migration do
  # Record time when policy loading is finished. This is mainly so that policy
  # log triggers can store a reference to the current policy version when it's
  # being loaded.
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

      -- Deferred constraint trigger will run on transaction commit.
      -- This enforces that loading policy version has to happen inside the 
      -- same transaction that created it, and that finished_at is never NULL
      -- once the transaction is committed.
      CREATE CONSTRAINT TRIGGER finish_current
        AFTER INSERT ON policy_versions
        INITIALLY DEFERRED
        FOR EACH ROW
        WHEN (NEW.finished_at IS NULL)
        EXECUTE PROCEDURE policy_versions_finish();

      -- If any version is current while creating new one, finalize it, so only
      -- a single policy is current at any given time.
      -- This shouldn't happen in normal policy loading, but is done in tests
      -- a bit. Alternatively we could raise an exception here and restructure
      -- tests to do it explicitly where needed.
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
