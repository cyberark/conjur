# # frozen_string_literal: true
#
Sequel.migration do
  up do
    execute 'CREATE OR REPLACE FUNCTION is_role_ancestor_of_any(role_id text, other_ids text[]) RETURNS boolean
                 LANGUAGE sql STABLE STRICT
               AS $$
                 SELECT EXISTS (
                   WITH RECURSIVE m(id) AS (
                     SELECT $1
                       UNION
                     SELECT role_id FROM role_memberships rm INNER JOIN m ON member_id = id
                   )
                   SELECT true FROM m WHERE id = ANY ($2) LIMIT 1
                ) _
              $$;'

    execute 'CREATE OR REPLACE FUNCTION is_role_allowed_to(role_id text, privilege text, resource_id text) RETURNS boolean
                 LANGUAGE sql STABLE STRICT
               AS $$
                 WITH allowed_roles(roles) AS (
                   SELECT array_agg(CAST(p.role_id AS text)) FILTER (WHERE p.role_id IS NOT NULL) || r.owner_id AS roles
                   FROM resources r LEFT JOIN permissions p ON r.resource_id = p.resource_id AND p.privilege = $2
                   WHERE r.resource_id = $3
                   GROUP BY r.resource_id
                 )
                 SELECT COALESCE(is_role_ancestor_of_any($1, ar.roles), false) FROM allowed_roles ar
               $$;'
  end
end
