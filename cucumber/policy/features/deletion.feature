Feature: Deleting objects and relationships.

  Objects and relationships can be explicitly deleted using the !delete,
  !revoke, and !deny statements.

  Scenario: The !delete statement can be used to delete an object.
    Given I load a policy:
    """
    - !group developers
    """
    Then group "developers" exists
    And I update the policy with:
    """
    - !delete
      record: !group developers
    """
    Then group "developers" does not exist

  Scenario: The !revoke statement can be used to revoke a role grant.
    Given I load a policy:
    """
    - !group developers
    - !group employees
    - !grant
      role: !group employees
      member: !group developers
    """
    And I show the group "employees"
    Then group "developers" is a role member
    And I update the policy with:
    """
    - !revoke
      role: !group employees
      member: !group developers
    """
    And I show the group "employees"
    Then group "developers" is not a role member


  Scenario: The !deny statement can be used to revoke a permission.
    Given I load a policy:
    """
    - !variable db/password
    - !host host-01
    - !permit
      resource: !variable db/password
      privileges: [ read, execute, update ]
      role: !host host-01
    """
    And I list the roles permitted to update variable "db/password"
    Then the role list includes host "host-01"
    And I update the policy with:
    """
    - !deny
      resource: !variable db/password
      privileges: [ update ]
      role: !host host-01
    """
    And I list the roles permitted to execute variable "db/password"
    Then the role list includes host "host-01"
    And I list the roles permitted to update variable "db/password"
    Then the role list does not include host "host-01"
