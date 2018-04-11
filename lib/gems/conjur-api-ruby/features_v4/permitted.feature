Feature: Check if a role has permission on a resource.

  Scenario: Check if the current user has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute'
    """
    Then the result should be "true"

  Scenario: Check if a different user has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute', role: "cucumber:user:bob"
    """
    Then the result should be "false"
