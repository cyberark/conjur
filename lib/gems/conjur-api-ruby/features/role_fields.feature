Feature: Display basic role fields.

  Scenario: Login of a user is the login name.
    When I run the code:
    """
    $conjur.role('cucumber:user:alice').login
    """
    Then the result should be "alice"

  Scenario: Login of a non-user is prefixed with the role kind.
    When I run the code:
    """
    $conjur.role('cucumber:host:myapp').login
    """
    Then the result should be "host/myapp"
