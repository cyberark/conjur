Feature: Replacing a policy

A policy can be reloaded using the --replace flag

  Scenario: A multifile policy with one modified file fails on reload

    Given I replace the policy by loading the policy file "multifile1.yml"
    And I load a "root" policy file "multifile2.yml"
    When I replace the policy by loading the policy file "multifile2_with_deletes.yml"
    Then there is an error
    And the error code is "not_found"
    And the error message is "ID cucumber:group:developers is not a valid role"

  Scenario: Policy reload fails when group isn't defined in new policy

    Given I replace the policy by loading the policy file "multifile1.yml"
    And I replace the policy by loading the policy file "multifile2.yml"
    Then there is an error
    And the error code is "not_found"
    And the error message is "ID cucumber:group:security-admin is not a valid role"

  Scenario: A multifile policy successfully reloads when files are concatenated

    Given I replace the policy by loading the policy file "multifile1.yml"
    And I load a "root" policy file "multifile2.yml"
    Then user "developer1" exists
    And I show the group "developers"
    Then user "developer1" is a role member
    And I replace the policy by loading the concatenated policy files "multifile1.yml multifile2_with_deletes.yml"
    Then there is no error
    Then user "developer1" does not exist
    And I show the group "developers"
    Then user "developer1" is not a role member
