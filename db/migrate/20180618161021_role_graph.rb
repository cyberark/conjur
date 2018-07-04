# frozen_string_literal: true

Sequel.migration do
  up do
    execute %Q{
      CREATE TYPE role_graph_edge AS (
        parent text,
        child text
      );

      CREATE OR REPLACE FUNCTION role_graph(start_role text)
      RETURNS SETOF role_graph_edge
      LANGUAGE SQL STABLE
      CALLED ON NULL INPUT
      AS $$

        WITH RECURSIVE 
        -- Ancestor tree
        up AS (
          (SELECT role_id, member_id FROM role_memberships LIMIT 0)
          UNION ALL
            SELECT start_role, NULL

          UNION

          SELECT rm.role_id, rm.member_id FROM role_memberships rm, up
          WHERE up.role_id = rm.member_id
        ),

        -- Descendent tree
        down AS (
            (SELECT role_id, member_id FROM role_memberships LIMIT 0)
          UNION ALL
            SELECT NULL, start_role

          UNION

          SELECT rm.role_id, rm.member_id FROM role_memberships rm, down
          WHERE down.member_id = rm.role_id
        ),

        total AS (
          SELECT * FROM up
          UNION

          -- add immediate children of the ancestors
          -- (they can be fetched anyway through role_members method)
          SELECT rm.role_id, rm.member_id FROM role_memberships rm, up WHERE rm.role_id = up.role_id

          UNION
          SELECT * FROM down
        )

        SELECT * FROM total WHERE role_id IS NOT NULL AND member_id IS NOT NULL
        UNION
        SELECT role_id, member_id FROM role_memberships WHERE start_role IS NULL

      $$;

      COMMENT ON FUNCTION role_graph(text) IS
      'if role is not null, returns role_memberships culled to include only the two trees rooted at given role, plus the skin of the up tree; otherwise returns all of role_memberships';

    }
  end

  down do
    execute %Q{
      DROP FUNCTION role_graph(start_role text);
      DROP TYPE role_graph_edge;
    }
  end
end
