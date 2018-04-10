Sequel.migration do
  up do
    alter_table :policy_versions do
      set_column_type :created_at, :timestamptz
      add_column :commited_at, :timestamptz,
        index: true, # to quickly find the null
        null: true # will be enforced by a trigger
      add_constraint(:created_before_commit) { created_at <= commited_at }
    end

    execute """
      CREATE OR REPLACE FUNCTION policy_versions_commit()
        RETURNS trigger
      LANGUAGE plpgsql AS $$
        BEGIN
          UPDATE policy_versions pv
            SET commited_at = clock_timestamp()
            WHERE commited_at IS NULL;
          RETURN new;
        END;
      $$;

      -- deferred constraint trigger will run on transaction commit
      CREATE CONSTRAINT TRIGGER commit_current
        AFTER INSERT ON policy_versions
        INITIALLY DEFERRED
        FOR EACH ROW
        WHEN (NEW.commited_at IS NULL)
        EXECUTE PROCEDURE policy_versions_commit();

      -- if any version is current while creating new one, commit it
      CREATE TRIGGER only_one_current
        BEFORE INSERT ON policy_versions
        FOR EACH ROW
        EXECUTE PROCEDURE policy_versions_commit();

      CREATE FUNCTION current_policy_version()
        RETURNS SETOF policy_versions
        SET search_path FROM CURRENT
        LANGUAGE sql STABLE AS $$
          SELECT * FROM policy_versions WHERE commited_at IS NULL $$;
    """
  end

  down do
    execute """
      DROP FUNCTION current_policy_version();
      DROP TRIGGER commit_current ON policy_versions;
      DROP TRIGGER only_one_current ON policy_versions;
      DROP FUNCTION policy_versions_commit();
    """

    alter_table :policy_versions do
      drop_column :commited_at
      set_column_type :created_at, :timestamp
    end
  end
end
