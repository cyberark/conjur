@policies
Feature: Policies can refer to each other by relative path.

  @smoke
  Scenario: Two sibling policies can refer to each other by relative path.

    A policy can grant its own roles and permissions to roles in other policies.
    The `role` attribute of the `!permit` statement and the `member` attribute of the
    `!grant` statement can both use relative paths in their id. The relative path
    is expanded the way you would expect; `..` is converted to the id of the 
    enclosing policy. So, the expression `../frontend` used in a policy `prod/database`
    is resolved to the path `prod/frontend`. 
  
    Given I load a policy:
    """
    - !policy
      id: prod
      body:
      - !policy
        id: frontend
        body:
        - !layer

      - !policy
        id: database
        body:
        - !variable password

        - !permit
          role: !layer ../frontend
          privilege: [ read, execute ]
          resource: !variable password

    - !host host-01

    - !grant
      role: !layer prod/frontend
      member: !host host-01
    """
    And I log in as user "admin"
    And I can add a secret to variable resource "prod/database/password"
    When I log in as host "host-01"
    Then I can fetch a secret from variable resource "prod/database/password"

  @acceptance
  Scenario: Policy references can be used across policy loader invocations.
    Given I load a policy:
    """
    - !policy
      id: prod
      body:
      - !policy database
      - !policy frontend
    """
    And I replace the "prod/frontend" policy with:
    """
    - !layer
    """
    Then I replace the "prod/database" policy with:
    """
    - !variable password
    - !permit
      role: !layer ../frontend
      privilege: [ read, execute ]
      resource: !variable password
    """
