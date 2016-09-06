Sequel.migration do
  up do
    execute <<-SQL_CODE

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
    BEGIN
      SELECT * INTO rolsource_role FROM roles WHERE roles.role_id = $1;
      IF FOUND THEN
        INSERT INTO role_memberships ( role_id, member_id, admin_option, ownership )
          VALUES ( $1, $2, true, true );
        RETURN 1;
      END IF;
      RETURN 0;
    END
    $$;

    CREATE OR REPLACE FUNCTION resources_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      PERFORM grant_role_membership_to_owner(NEW.resource_id, NEW.owner_id);
      RETURN NEW;
    END
    $$;

    CREATE OR REPLACE FUNCTION resources_update_trigger() RETURNS trigger
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

    CREATE OR REPLACE FUNCTION resources_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      PERFORM delete_role_membership_of_owner(OLD.resource_id, OLD.owner_id);

      RETURN OLD;
    END
    $$;

    CREATE TRIGGER resources_insert_trigger
    BEFORE INSERT
    ON resources
    FOR EACH ROW
    EXECUTE PROCEDURE resources_insert_trigger();

    CREATE TRIGGER resources_update_trigger
    BEFORE UPDATE
    ON resources
    FOR EACH ROW
    EXECUTE PROCEDURE resources_update_trigger();

    CREATE TRIGGER resources_delete_trigger
    BEFORE DELETE
    ON resources
    FOR EACH ROW
    EXECUTE PROCEDURE resources_delete_trigger();

    SQL_CODE
  end

  down do
    execute <<-SQL_CODE

    DROP FUNCTION resources_delete_trigger() CASCADE;
    DROP FUNCTION resources_update_trigger() CASCADE;
    DROP FUNCTION resources_insert_trigger() CASCADE;
    DROP FUNCTION grant_role_membership_to_owner(text, text);
    DROP FUNCTION delete_role_membership_of_owner(text, text);

    SQL_CODE
  end
end
