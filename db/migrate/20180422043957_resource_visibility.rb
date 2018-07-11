# frozen_string_literal: true

Sequel.migration do
  up do
    execute """
      CREATE OR REPLACE FUNCTION visible_resources(role_id text)
      RETURNS SETOF resources
      LANGUAGE sql STABLE STRICT AS $$
        WITH
          all_roles AS (SELECT * FROM all_roles(role_id)),
          permitted AS (
            SELECT DISTINCT resource_id FROM permissions NATURAL JOIN all_roles
          )
        SELECT *
          FROM resources
          WHERE
            -- resource is visible if there are any permissions or ownerships held on it
            owner_id IN (SELECT role_id FROM all_roles)
            OR resource_id IN (SELECT resource_id FROM permitted)
      $$
    """

    execute """
      CREATE OR REPLACE FUNCTION is_resource_visible(resource_id text, role_id text)
      RETURNS boolean
      LANGUAGE sql STABLE STRICT AS $$
        WITH RECURSIVE search(role_id) AS (
          -- We expand transitively back from the set of roles that the
          -- resource is visible to instead of relying on all_roles().
          -- This has the advantage of not being sensitive to the size of the
          -- role graph of the argument and hence offers stable performance
          -- even when a powerful role is tested, at the expense of slightly
          -- worse performance of a failed check for a locked-down role.
          -- This way all checks take ~ 1 ms regardless of the role.
          SELECT owner_id FROM resources WHERE resource_id = $1
            UNION
          SELECT role_id FROM permissions WHERE resource_id = $1
            UNION
          SELECT m.member_id
            FROM role_memberships m NATURAL JOIN search s
        )
        SELECT COUNT(*) > 0 FROM (
          SELECT true FROM search
            WHERE role_id = $2
            LIMIT 1 -- early cutoff: abort search if found
        ) AS found
      $$;
    """
  end

  down do
    execute "DROP FUNCTION is_resource_visible(text, text)"
    execute "DROP FUNCTION visible_resources(text)"
  end
end
