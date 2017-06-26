{% include toc.md key='statement-reference' section='entitlements' %}

Entitlements are role and privilege grants. `grant` is used to grant a `role` to a `member`. `permit` is used to give a `privilege` on a `role` to a resource.

Entitlements provide the "glue" between policies, creating permission relationships between different roles and subsystems. For example, a policy for an application may define a `secrets-managers` group which can administer the secrets in the policy. An entitlement will grant the policy-specific `secrets-managers` group to a global organizational group such as `operations` or `people/teams/frontend`.

