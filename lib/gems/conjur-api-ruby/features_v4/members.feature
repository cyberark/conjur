Feature: Display role members and memberships.

  Scenario: Show a role's members.
    When I run the code:
    """
    $conjur.role('cucumber:group:everyone').members.map(&:as_json)
    """
    Then the JSON should be:
    """
    [
      {
        "admin_option": false,
        "member": "cucumber:group:developers",
        "role": "cucumber:group:everyone"
      },
      {
        "admin_option": true,
        "member": "cucumber:group:security_admin",
        "role": "cucumber:group:everyone"
      }
    ]
    """

  Scenario: Show a role's memberships.
    When I run the code:
    """
    $conjur.role('cucumber:group:developers').memberships.map(&:as_json)
    """
    Then the JSON should be:
    """
    [
      {
        "id": "cucumber:group:developers"
      },
      {
        "id": "cucumber:group:everyone"
      }
    ]
    """
