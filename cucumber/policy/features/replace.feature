Feature: Replacing a policy

A policy can be reloaded using the --replace flag

  Scenario: A multifile policy with one modified file fails on reload

    Given I replace the policy by loading the policy file "multifile1.yml"
    And I load a "root" policy file "multifile2.yml"
    When I replace the policy by loading the policy file "multifile2_with_deletes.yml"
    Then the error code is "422"
    And the error message is "you have made an error"
