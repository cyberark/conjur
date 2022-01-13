@policy
Feature: Custom ownership can be assigned to a policy object.

  By default, each object in a policy is owned by the policy.
  This means that the policy role has full admin rights to the objects within
  it.

  However, ownership of each object can be assigned to a role other than the
  policy.

  @smoke
  Scenario: The default owner of a policy-scoped object is the policy.
    Given I load a policy:
    """
    - !user bob

    - !policy
      id: db
      body:
      - !variable password
    """
    Then the owner of user "bob" is user "admin"
    And  the owner of variable "db/password" is policy "db"

  @smoke
  Scenario: The owner of a policy-scoped object can be changed.
    Given I load a policy:
    """
    - !group secrets-managers

    - !variable
      id: password
      owner: !group secrets-managers
    """
    Then the owner of variable "password" is group "secrets-managers"
