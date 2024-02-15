# frozen_string_literal: true

Sequel.migration do
  up do
    # Returns a list of all resources in the database which have this policy id
    # as a direct or eventual parent. (This includes the policy resource itself)
    execute %Q(CREATE OR REPLACE FUNCTION policy_resources(policy_id text) RETURNS TABLE(resource_id text, policy_id text)
      LANGUAGE sql STABLE STRICT
      AS $_$
          SELECT resource_id, policy_id FROM resources
            WHERE position(concat(identifier($1), '/') in identifier(resource_id)) = 1
            OR resource_id = $1;
      $_$;)

    # Determines if a given role has update permissions on the given policy
    # and all of the child resources of that policy.
    execute %Q(CREATE OR REPLACE FUNCTION policy_permissions(role_id text, permission text, policy_id text) RETURNS boolean
      LANGUAGE sql STABLE STRICT
      AS $_$
        SELECT bool_and(is_role_allowed_to($1, $2, resource_id))
        FROM policy_resources($3);
      $_$;)
  end

  down do
    execute %Q(DROP FUNCTION policy_resources(text))
    execute %Q(DROP FUNCTION policy_permissions(text, text))
  end
end
