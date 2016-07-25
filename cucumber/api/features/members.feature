@logged-in
Feature: Listing role members

  Scenario: Initial roles members is just the initial role admin.
    Given a new user "bob"
    When I list the user's members
    Then the JSON should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin"
      }
    ]
    """

  Scenario: New member roles appear in the role list.
    Given a new user "bob"
    And I grant user "alice" to user "bob"
    When I list the user's members
    Then the JSON should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:bob"
      }
    ]
    """
