@policy
Feature: Deleting objects and relationships.

  Objects and relationships can be explicitly deleted using the !delete,
  !revoke, and !deny statements.

  @smoke
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

  @acceptance
  Scenario: Deleting variable value is unrecoverable.
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    And variable "test/db-password" exists
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I update the policy with:
    """
    - !policy
      id: test
      body:
      - !delete
        record: !variable db-password
    """
    And I extend the policy with:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    Then variable "test/db-password" exists
    And variable resource "test/db-password" does not have a secret value

  @acceptance
  Scenario: Deleting variable value is unrecoverable even if we add same variable with the delete policy
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    And variable "test/db-password" exists
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I update the policy with:
    """
    - !policy
      id: test
      body:
      - !delete
        record: !variable db-password
    """
    And I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    Then variable "test/db-password" exists
    And variable resource "test/db-password" does not have a secret value

  @acceptance
  Scenario: Deleting variable value is unrecoverable when we delete the policy itself and then add it again
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    And variable "test/db-password" exists
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I update the policy with:
    """
    - !delete
      record: !policy test
    """
    And I extend the policy with:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    Then variable "test/db-password" exists
    And variable resource "test/db-password" does not have a secret value

  @smoke
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

  @smoke
  Scenario: The bulk !revoke statement can be used to revoke multiple roles and members.
    Given I load a policy:
    """
    - !group developers1
    - !group developers2
    - !group developers3
    - !group employees1
    - !group employees2
    - !group employees3
    - !grant
      roles:
        - !group employees1
        - !group employees2
        - !group employees3
      members:
        - !group developers1
        - !group developers2
        - !group developers3
    """
    When I show the group "employees1"
    Then group "developers1" is a role member
    And group "developers2" is a role member
    And group "developers3" is a role member
    When I show the group "employees2"
    Then group "developers1" is a role member
    And group "developers2" is a role member
    And group "developers3" is a role member
    When I show the group "employees3"
    Then group "developers1" is a role member
    And group "developers2" is a role member
    And group "developers3" is a role member
    When I update the policy with:
    """
    - !revoke
      roles:
        - !group employees1
        - !group employees2
      members:
        - !group developers1
        - !group developers2
    """
    And I show the group "employees1"
    Then group "developers1" is not a role member
    And group "developers2" is not a role member
    And group "developers3" is a role member
    When I show the group "employees2"
    Then group "developers1" is not a role member
    And group "developers2" is not a role member
    And group "developers3" is a role member
    When I show the group "employees3"
    Then group "developers1" is a role member
    And group "developers2" is a role member
    And group "developers3" is a role member

  @smoke
  Scenario: The !deny statement can be used to revoke permissions.
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
      privileges: [ update, read ]
      role: !host host-01
    """
    And I list the roles permitted to execute variable "db/password"
    Then the role list includes host "host-01"
    And I list the roles permitted to update variable "db/password"
    Then the role list does not include host "host-01"
    And I list the roles permitted to read variable "db/password"
    Then the role list does not include host "host-01"

  @smoke
  Scenario: The bulk !deny statement can be used to revoke a permission from roles and members.
    Given I load a policy:
    """
    - !variable db/address
    - !variable db/username
    - !variable db/password
    - !host host-01
    - !host host-02
    - !host host-03
    - !permit
      resources:
        - !variable db/address
        - !variable db/username
        - !variable db/password
      privileges: [ update ]
      roles:
        - !host host-01
        - !host host-02
        - !host host-03
    """
    And I list the roles permitted to update variable "db/address"
    Then the role list includes host "host-01"
    Then the role list includes host "host-02"
    Then the role list includes host "host-03"
    And I list the roles permitted to update variable "db/username"
    Then the role list includes host "host-01"
    Then the role list includes host "host-02"
    Then the role list includes host "host-03"
    And I list the roles permitted to update variable "db/password"
    Then the role list includes host "host-01"
    Then the role list includes host "host-02"
    Then the role list includes host "host-03"
    And I update the policy with:
    """
    - !deny
      resources:
        - !variable db/address
        - !variable db/username
      privileges: [ update ]
      roles:
        - !host host-01
        - !host host-02
    """
    When I list the roles permitted to update variable "db/address"
    Then the role list does not include host "host-01"
    And the role list does not include host "host-02"
    And the role list includes host "host-03"
    When I list the roles permitted to update variable "db/username"
    Then the role list does not include host "host-01"
    And the role list does not include host "host-02"
    And the role list includes host "host-03"
    When I list the roles permitted to update variable "db/password"
    Then the role list includes host "host-01"
    And the role list includes host "host-02"
    And the role list includes host "host-03"

    @smoke
    Scenario: Delete statements prevail on conflicting policy statements
      If a policy contains both adding and deleting statements (delete, deny, revoke),
      then we want to ensure that we fail safe and the delete statement is the final outcome.
      Given I update the policy with:
      """
      - !variable db/password
      - !host host-01
      - !permit
        resource: !variable db/password
        privileges: [ execute ]
        role: !host host-01
      - !deny
        resource: !variable db/password
        privileges: [ execute ]
        role: !host host-01
      """
      When I list the roles permitted to execute variable "db/password"
      Then the role list does not include host "host-01"
      Given I update the policy with:
      """
      - !group hosts
      - !grant
        role: !host host-01
        member: !group hosts
      - !revoke
        role: !host host-01
        member: !group hosts
      """
      When I show the group "hosts"
      Then host "host-01" is not a role member
      Given I update the policy with:
      """
      - !variable to_be_deleted
      - !delete
        record: !variable to_be_deleted
      """
      Then variable "to_be_deleted" does not exist
