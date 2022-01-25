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
