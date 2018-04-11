Feature: Check if an object exists.

  Scenario: A created group resource exists
    When I run the code:
    """
    $conjur.resource('cucumber:group:developers').exists?
    """
    Then the result should be "true"

  Scenario: An un-created resource doesn't exist
    When I run the code:
    """
    $conjur.resource('cucumber:food:bacon').exists?
    """
    Then the result should be "false"

  Scenario: A created group role exists
    When I run the code:
    """
    $conjur.role('cucumber:group:developers').exists?
    """
    Then the result should be "true"

  Scenario: An un-created role doesn't exist
    When I run the code:
    """
    $conjur.role('cucumber:food:bacon').exists?
    """
    Then the result should be "false"
