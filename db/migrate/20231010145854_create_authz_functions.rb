# frozen_string_literal: true

Sequel.migration do
  up do
    execute %Q(CREATE OR REPLACE FUNCTION all_roles(role_id text) RETURNS TABLE(role_id text, admin_option boolean)
    LANGUAGE sql STABLE STRICT ROWS 2376
    AS $_$
          WITH RECURSIVE m(role_id, admin_option) AS (
            SELECT $1, 't'::boolean
              UNION
            SELECT ms.role_id, ms.admin_option FROM role_memberships ms, m
              WHERE member_id = m.role_id
          ) SELECT role_id, bool_or(admin_option) FROM m GROUP BY role_id
        $_$;)

    execute %Q(CREATE OR REPLACE FUNCTION permitted_resources_per_role(role_id text, resource_like text, limit1 bigint, offset1 bigint) RETURNS table (resource_id text)
    LANGUAGE sql STABLE STRICT
    AS $_$
          WITH
            all_roles AS (SELECT role_id FROM all_roles($1))
            SELECT t.resource_id FROM (
              SELECT role_id, resources.resource_id FROM all_roles, resources
              WHERE owner_id = role_id
                AND resource_id LIKE $2
            UNION
              SELECT role_id, resources.resource_id FROM ( all_roles JOIN permissions USING ( role_id ) ) JOIN resources USING ( resource_id )
              WHERE privilege = 'execute'
                AND resource_id LIKE $2
            ) t GROUP BY t.resource_id ORDER BY t.resource_id LIMIT $3 OFFSET $4
        $_$;)

    execute %Q(CREATE OR REPLACE FUNCTION allowed_secrets_per_role1(role_id text, resource_like text, limit1 bigint, offset1 bigint)
    RETURNS table (resource_id text, value bytea, version text, owner_id text)
    LANGUAGE sql STABLE STRICT
    AS $_$
          WITH
            all_roles AS (SELECT role_id FROM all_roles($1))
            SELECT res.resource_id, secrets.value, secrets.version, res.owner_id FROM secrets JOIN (
            SELECT t.resource_id, t.owner_id FROM (
              SELECT role_id, resources.resource_id, owner_id FROM all_roles, resources
              WHERE owner_id = role_id
                AND resource_id LIKE $2
            UNION
              SELECT role_id, resources.resource_id, owner_id FROM ( all_roles JOIN permissions USING ( role_id ) ) JOIN resources USING ( resource_id )
              WHERE privilege = 'execute'
                AND resource_id LIKE $2
            ) t GROUP BY t.resource_id, t.owner_id ORDER BY t.resource_id LIMIT $3 OFFSET $4 ) AS res ON (res.resource_id = secrets.resource_id)
        $_$;)

    execute %Q(CREATE OR REPLACE FUNCTION is_role_allowed_to(role_id text, privilege text, resource_id text) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
        WITH
          all_roles AS (SELECT role_id FROM all_roles($1))
        SELECT COUNT(*) > 0 FROM (
          SELECT 1 FROM all_roles, resources
          WHERE owner_id = role_id
            AND resources.resource_id = $3
        UNION
          SELECT 1 FROM ( all_roles JOIN permissions USING ( role_id ) ) JOIN resources USING ( resource_id )
          WHERE privilege = $2
            AND resources.resource_id = $3
        ) AS _
      $_$;)

    execute %Q(CREATE OR REPLACE FUNCTION roles_that_can(permission text, resource_id text) RETURNS SETOF roles
    LANGUAGE sql STABLE STRICT ROWS 10
    AS $_$
          WITH RECURSIVE allowed_roles(role_id) AS (
            SELECT role_id FROM permissions
              WHERE privilege = $1
                AND resource_id = $2
            UNION SELECT owner_id FROM resources
                WHERE resources.resource_id = $2
            UNION SELECT member_id AS role_id FROM role_memberships ms NATURAL JOIN allowed_roles
            ) SELECT DISTINCT r.* FROM roles r NATURAL JOIN allowed_roles;
        $_$)
  end

  down do
    execute %Q(DROP FUNCTION roles_that_can(text, text))
    execute %Q(DROP FUNCTION is_role_allowed_to(text, text, text))
    execute %Q(DROP FUNCTION all_roles(text))
  end
end
