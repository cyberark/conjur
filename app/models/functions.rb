# frozen_string_literal: true

class Functions
  class << self
    def ownership_trigger_sql
      <<-SQL_CODE

      -- Deletes the role_memberships record with the indicated role and grantee (owner). The record may 
      -- not exist, if the resource with the indicated owner does not have a corresponding role.
      CREATE OR REPLACE FUNCTION delete_role_membership_of_owner(role_id text, owner_id text) RETURNS int
      LANGUAGE plpgsql
      AS $$
      DECLARE
        row_count int;
      BEGIN
        DELETE FROM role_memberships rm
          WHERE rm.role_id = $1 AND
            member_id = $2 AND
            ownership = true;
        GET DIAGNOSTICS row_count = ROW_COUNT;
        RETURN row_count;
      END
      $$;

      -- Inserts a role_memberships record with the indicated role and grantee (owner). If the
      -- role indicated by the role_id does not exist, then no insertion is performed.
      CREATE OR REPLACE FUNCTION grant_role_membership_to_owner(role_id text, owner_id text) RETURNS int
      LANGUAGE plpgsql
      AS $$
      DECLARE
        rolsource_role roles%rowtype;
        existing_grant role_memberships%rowtype;
      BEGIN
        SELECT * INTO rolsource_role FROM roles WHERE roles.role_id = $1;
        IF FOUND THEN
          SELECT * INTO existing_grant FROM role_memberships rm WHERE rm.role_id = $1 AND rm.member_id = $2 AND rm.admin_option = true AND rm.ownership = true;
          IF NOT FOUND THEN
            INSERT INTO role_memberships ( role_id, member_id, admin_option, ownership )
              VALUES ( $1, $2, true, true );
            RETURN 1;
          END IF;
        END IF;
        RETURN 0;
      END
      $$;

      CREATE OR REPLACE FUNCTION grant_role_membership_to_owner_trigger() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        PERFORM grant_role_membership_to_owner(NEW.resource_id, NEW.owner_id);
        RETURN NEW;
      END
      $$;

      CREATE OR REPLACE FUNCTION update_role_membership_of_owner_trigger() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        IF OLD.owner_id != NEW.owner_id THEN
          PERFORM delete_role_membership_of_owner(OLD.resource_id, OLD.owner_id);
          PERFORM grant_role_membership_to_owner(OLD.resource_id, NEW.owner_id);
        END IF;
        RETURN NEW;
      END
      $$;

      CREATE OR REPLACE FUNCTION delete_role_membership_of_owner_trigger() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        PERFORM delete_role_membership_of_owner(OLD.resource_id, OLD.owner_id);

        RETURN OLD;
      END
      $$;

      CREATE TRIGGER grant_role_membership_to_owner
      BEFORE INSERT
      ON resources
      FOR EACH ROW
      EXECUTE PROCEDURE grant_role_membership_to_owner_trigger();

      CREATE TRIGGER update_role_membership_of_owner
      BEFORE UPDATE
      ON resources
      FOR EACH ROW
      EXECUTE PROCEDURE update_role_membership_of_owner_trigger();

      CREATE TRIGGER delete_role_membership_of_owner
      BEFORE DELETE
      ON resources
      FOR EACH ROW
      EXECUTE PROCEDURE delete_role_membership_of_owner_trigger();

      SQL_CODE
    end

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
