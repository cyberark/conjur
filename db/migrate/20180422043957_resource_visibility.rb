Sequel.migration do
  up do
    execute """
      CREATE OR REPLACE RECURSIVE VIEW
        role_memberships_transitive(role_id, member_id) AS

      -- for simplicity: a role is its own member
      SELECT role_id, role_id FROM roles
      UNION

      -- go members up for efficient filtering
      SELECT m.role_id, t.member_id
      FROM
        role_memberships m,
        role_memberships_transitive t
      WHERE
        m.member_id = t.role_id
    """

    execute """
      CREATE OR REPLACE VIEW permissions_transitive AS
      SELECT privilege, resource_id, member_id AS role_id
      FROM (
        SELECT privilege, resource_id, role_id FROM permissions p
        UNION
        -- ownership is represented by a NULL (ie. wildcard) permission
        SELECT NULL, resource_id, owner_id AS role_id FROM resources
      ) AS _
      JOIN role_memberships_transitive m
      USING (role_id)
    """

    execute """
      CREATE OR REPLACE VIEW visible_resources AS
      SELECT DISTINCT resource_id, role_id
      FROM permissions_transitive t
      """
  end

  down do
    execute "DROP VIEW visible_resources"
    execute "DROP VIEW permissions_transitive"
    execute "DROP VIEW role_memberships_transitive"
  end
end
