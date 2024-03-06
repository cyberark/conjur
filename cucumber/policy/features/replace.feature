@policy
Feature: Replacing a policy

A policy can be reloaded using the --replace flag

  @negative @acceptance
  Scenario: A multifile policy with one modified file fails on reload

    Given I load a policy:
    """
    - !group
      id: security-admin
      owner: !user admin

    - !group
      id: developers-admin
      owner: !group security-admin

    - !group
      id: developers
      owner: !group developers-admin
    """
    And I extend the policy with:
    """
    - !user
      id: developer1
      owner: !group security-admin

    - !user
      id: developer2
      owner: !group security-admin

    - !grant
      role: !group developers
      members:
      - !user developer1
      - !user developer2
    """
    When I replace the "root" policy with:
    """
    - !user
      id: developer2
      owner: !group security-admin

    - !grant
      role: !group developers
      members:
      - !user developer2
    """
    Then there's an error
    And the error code is "not_found"
    And the error message is "Group 'developers' not found in account 'cucumber'"

  @negative @acceptance
  Scenario: Policy reload fails when group isn't defined in new policy

    Given I load a policy:
    """
    - !group
      id: security-admin
      owner: !user admin

    - !group
      id: developers-admin
      owner: !group security-admin

    - !group
      id: developers
      owner: !group developers-admin
    """
    When I replace the "root" policy with:
    """
    - !user
      id: developer1
      owner: !group security-admin

    - !user
      id: developer2
      owner: !group security-admin

    - !grant
      role: !group developers
      members:
      - !user developer1
      - !user developer2
    """
    Then there's an error
    And the error code is "not_found"
    And the error message is "Group 'security-admin' not found in account 'cucumber'"

  @smoke
  Scenario: Removing variable declaration from policy deletes its value
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I load a policy:
    """
    - !policy
      id: test
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
  Scenario: Removing policy with variable declaration deletes its value
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I load a policy:
    """
    - !policy empty
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
  Scenario: Replacing policy with variable declaration keeps variable's secret value
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    Then variable "test/db-password" exists
    And I can fetch a secret from variable resource "test/db-password"

  @acceptance
  Scenario: Replacing policy root with same policy tests replaces the variable
    Given I load a policy:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    # Variable loaded twice so we verify we delete all of its versions
    And I can add a secret to variable resource "test/db-password"
    And I can add a secret to variable resource "test/db-password"
    And I can fetch a secret from variable resource "test/db-password"
    When I replace the "root" policy with:
    """
    - !policy
      id: test
      body:
      - !variable db-password
    """
    Then variable "test/db-password" exists
    And I can fetch a secret from variable resource "test/db-password"

  @smoke
  Scenario: A multifile policy successfully reloads when files are concatenated

    Given I load a policy:
    """
    - !group
      id: security-admin
      owner: !user admin

    - !group
      id: developers-admin
      owner: !group security-admin

    - !group
      id: developers
      owner: !group developers-admin
    """
    And I extend the policy with:
    """
    - !user
      id: developer1
      owner: !group security-admin

    - !user
      id: developer2
      owner: !group security-admin

    - !grant
      role: !group developers
      members:
      - !user developer1
      - !user developer2
    """
    Then user "developer1" exists
    And I show the group "developers"
    Then user "developer1" is a role member
    And I replace the "root" policy with:
    """
    - !group
      id: security-admin
      owner: !user admin

    - !group
      id: developers-admin
      owner: !group security-admin

    - !group
      id: developers
      owner: !group developers-admin

    - !user
      id: developer2
      owner: !group security-admin

    - !grant
      role: !group developers
      members:
      - !user developer2
    """
    Then there's no error
    Then user "developer1" does not exist
    And I show the group "developers"
    Then user "developer1" is not a role member

  @negative @acceptance
  Scenario: Loading a policy that references a removed resource produces a Not Found exception

    Given I load a policy:
    """
    - !host jenkins-ops-secrets

    - !layer ops

    - !permit
      role: !host jenkins-ops-secrets
      privileges:
        - read
        - execute 
      resource: !layer ops
    """
    When I replace the "root" policy with:
    """
    - !host jenkins-ops-secrets

    - !permit
      role: !host jenkins-ops-secrets
      privileges:
        - read
        - execute
      resource: !layer ops
    """
    Then there's an error
    And the error code is "not_found"
    And the error message is "Layer 'ops' not found in account 'cucumber'"

  @acceptance
  Scenario: Update the policy with a policy that contains not yet existing element

    Given I load a policy:
    """
    - !policy
      id: testpolicy
      body:
        - !policy
          id: testsubpolicy
          owner: !host testhost
        - !host
          id: testhost
    """
    And I update the policy with:
    """
    - !policy
      id: testpolicy
      body:
        - !host
          id: testhost
        - !group
          id: testgroup
        - !grant
          role: !group testgroup
          member: !host testhost
        - !policy
          id: testsubpolicy
          owner: !group testgroup
    """
    When I list group resources
    Then the resource list includes group "testpolicy/testgroup"

  @acceptance
  Scenario: Replace the policy with a policy that contains not yet existing element

    Given I load a policy:
    """
    - !policy
      id: testpolicy
      body:
        - !policy
          id: testsubpolicy
          owner: !host testhost
        - !host
          id: testhost
    """
    And I replace the "root" policy with:
    """
    - !policy
      id: testpolicy
      body:
        - !host
          id: testhost
        - !group
          id: testgroup
        - !grant
          role: !group testgroup
          member: !host testhost
        - !policy
          id: testsubpolicy
          owner: !group testgroup
    """
    When I list group resources
    Then the resource list includes group "testpolicy/testgroup"
