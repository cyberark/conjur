Sequel.migration do
  up do
    execute <<-SQL
        CREATE MATERIALIZED VIEW IF NOT EXISTS all_roles_view
        AS (
        WITH RECURSIVE all_roles_inner(role_id, child_id, admin_option) AS (
            SELECT role_id, member_id as child_id, admin_option
            FROM role_memberships
            UNION
            SELECT t.role_id, child_id, t.admin_option
            FROM role_memberships t
            JOIN all_roles_inner
                ON t.member_id = all_roles_inner.role_id
        ) select role_id, child_id, admin_option FROM all_roles_inner
        );
        CREATE INDEX ari_role_idx ON all_roles_view(role_id);
        CREATE INDEX ari_child_idx ON all_roles_view(child_id);

        CREATE OR REPLACE FUNCTION all_roles(role_id text) RETURNS table(role_id text, admin_option boolean)
        language sql
        AS $_$
        SELECT $1, 't'::boolean
        UNION
        SELECT role_id, bool_or(admin_option) FROM all_roles_view where child_id = $1 group by role_id
        $_$;

        CREATE MATERIALIZED VIEW resources_view as (SELECT *, account(resource_id), identifier(resource_id), kind(resource_id) FROM resources);
        CREATE INDEX identifier_idx ON resources_view(identifier);
        CREATE INDEX kind_idx ON resources_view(kind);
        CREATE INDEX account_idx ON resources_view(account);

        CREATE OR REPLACE FUNCTION cluster_members(policy_name text, address_col_name text) RETURNS TABLE(name text, address text)
        language sql
        AS $_$
        SELECT r.resource_id AS name, a.value AS address FROM resources_view r
        LEFT OUTER JOIN annotations a ON a.resource_id = r.resource_id AND a.name = address_col_name
        WHERE r.identifier LIKE policy_name || '/%'
        ORDER BY name
        $_$;

        CREATE OR REPLACE FUNCTION policy_exists(account text, policy_name text) RETURNS boolean
        language sql
        AS $_$
        SELECT COUNT(*) > 0 FROM resources_view r
        WHERE r.account = account AND
                r.kind = 'policy' AND
                r.identifier = policy_name
        $_$;
    SQL
  end
end
