# frozen_string_literal: true

Sequel.migration do
  up do
    execute %Q{
      CREATE FUNCTION is_role_ancestor_of(role_id text, other_id text)
         RETURNS boolean
         LANGUAGE sql
         STABLE STRICT
      AS $$
        SELECT COUNT(*) > 0 FROM (
          WITH RECURSIVE m(id) AS (
            SELECT $2
            UNION ALL
            SELECT role_id FROM role_memberships rm, m WHERE member_id = id
          )
          SELECT true FROM m WHERE id = $1 LIMIT 1
        )_
      $$;
    }
  end

  down do
    execute %Q{DROP FUNCTION is_role_ancestor_of(text, text)}
  end
end
