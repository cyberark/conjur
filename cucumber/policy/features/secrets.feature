@policy
Feature: Secrets can be managed through policies.

  Each resource in Conjur can have an associated list of secrets. Secrets on a resource
  support two operations, which correspond to `execute` and `update` privileges:

  - **update** Adds a new value to the secrets list.
  - **execute** Fetches a value from the secrets list.

  When the value of a secrets is updated, it's added to an internal list of secret values.
  Old secret values can still be obtained (up to a limit of retained history, which is currently
  20 values).

  By convention, secrets are stored in Conjur using a resource called a `variable`. 

  @smoke
  Scenario: The owner of a secret has full privileges to it.

    Because the owner of a resource has all privileges on the resource, the owner of a resource
    can both add and fetch secret values.

    Given I load a policy:
    """
    - !group secrets-managers

    - !user alice

    - !grant
      role: !group secrets-managers
      member: !user alice

    - !variable
      id: db-password
      owner: !group secrets-managers
    """
    And I log in as user "alice"
    Then there is a variable resource "db-password"
    And I can add a secret to variable resource "db-password"
    And I can retrieve the same secret value from "db-password"

  @smoke
  Scenario: Privilege grants can be used to delegate secrets permissions.

    The `update` privilege conveys the right to update a secret.

    `execute` privilege convays the right to fetch a secret. Having `update` privilege
    does not give the privilege to `execute`, the permissions are managed separately.

    Given I load a policy:
    """
    - !group secrets-fetchers

    - !group secrets-updaters

    - !user alice

    - !user bob

    - !grant
      role: !group secrets-fetchers
      member: !user alice

    - !grant
      role: !group secrets-updaters
      member: !user bob

    - !variable
      id: db-password

    - !permit
      resource: !variable db-password
      privileges: [ read, execute ]
      role: !group secrets-fetchers

    - !permit
      resource: !variable db-password
      privileges: [ read, update ]
      role: !group secrets-updaters
    """
    And I log in as user "bob"
    Then I can add a secret to variable resource "db-password"
    And I can not fetch a secret from variable resource "db-password"
    When I log in as user "alice"
    Then I can not add a secret to variable resource "db-password"
    And I can fetch a secret from variable resource "db-password"

  @acceptance
  Scenario: Defining secrets which are available to a Layer

    A policy which is used to define an application will typically include a layer.
    The layer is given any privileges which will be needed by the application hosts
    (code, containers, etc). When the application will need to access specific secrets,
    the secrets can be define in the policy as variables. The application layer is 
    given `read` and `execute` permission on the variable, and a `secrets-managers` group is typically
    created which has all privileges on the variable.

    Given I load a policy:
    """
    - !policy
      id: myapp
      body:
      - &variables
        - !variable db-password
        - !variable ssl/cert
        - !variable ssl/private_key

      - !group secrets-managers

      - !layer

      - !permit
        role: !layer
        privileges: [ read, execute ]
        resources: *variables

      - !permit
        role: !group secrets-managers
        privileges: [ read, execute, update ]
        resources: *variables

    - !user alice

    - !host myapp-01

    - !grant
      role: !layer myapp
      member: !host myapp-01

    - !grant
      role: !group myapp/secrets-managers
      member: !user alice
    """
    And I log in as user "alice"
    Then I can add a secret to variable resource "myapp/db-password"
    And I can fetch a secret from variable resource "myapp/db-password"
    And I log in as host "myapp-01"
    And I can not add a secret to variable resource "myapp/db-password"
    And I can fetch a secret from variable resource "myapp/db-password"
