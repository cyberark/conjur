@logged-in
Feature: Listing role members

  Background:
    Given a new user "alice"
    And a new user "bob"

  Scenario: Initial roles members is just the initial role admin.
    When I successfully GET "/roles/:account/user/alice@:user_namespace"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "grantor": "cucumber:user:alice",
        "member": "cucumber:user:admin",
        "role": "cucumber:user:alice"
      }
    ]
    """

  Scenario: New member roles appear in the role list.
    Given I grant user "alice" to user "bob"
    When I successfully GET "/roles/:account/user/alice@:user_namespace"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "grantor": "cucumber:user:alice",
        "member": "cucumber:user:admin",
        "role": "cucumber:user:alice"
      },
      {
        "admin_option": false,
        "grantor": "cucumber:user:alice",
        "member": "cucumber:user:bob",
        "role": "cucumber:user:alice"
      }
    ]
    """
