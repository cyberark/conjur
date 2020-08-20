Feature: Replacing a policy

A policy can be reloaded using the --replace flag

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
    Then there is an error
    And the error code is "not_found"
    And the error message is "Role cucumber:group:developers does not exist"

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
    Then there is an error
    And the error code is "not_found"
    And the error message is "Role cucumber:group:security-admin does not exist"

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
    Then there is no error
    Then user "developer1" does not exist
    And I show the group "developers"
    Then user "developer1" is not a role member
