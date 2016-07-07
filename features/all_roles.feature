@logged-in
Feature: Listing all roles of a role

  Scenario: Initial roles is just the owner.
    Given a new user "bob"
    When I list the user's roles
    Then the JSON should be:
    """
    [
      "cucumber:user:alice"
    ]
    """

  Scenario: Granted roles appear in the role list.
    Given a new user "bob"
    And I grant user "bob" to user "alice"
    When I list the user's roles
    Then the JSON should be:
    """
    [
      "cucumber:user:alice",
      "cucumber:user:bob"
    ]
    """

  Scenario: The role list can be filtered.
    Given a new user "bob"
    And I grant user "bob" to user "alice"
    Given a new user "charles"
    And I grant user "charles" to user "alice"
    Given a new user "dave"
    When I intersect the users "bob,charles,dave" with the user's roles
    Then the JSON should be:
    """
    [
      "cucumber:user:bob",
      "cucumber:user:charles"
    ]
    """
