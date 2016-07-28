@logged-in
Feature: Listing all roles of a role

  Scenario: The initial memberships of a role is just the role itself.
    Given a new user "bob"
    When I successfully GET "/roles/:account/user/alice@:user_namespace?all"
    Then the JSON should be:
    """
    [
      "cucumber:user:alice"
    ]
    """

  Scenario: Granted roles appear in a role's memberships.
    Given a new user "bob"
    And I grant user "bob" to user "alice"
    When I successfully GET "/roles/:account/user/alice@:user_namespace?all"
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
    When I successfully GET "/roles/:account/user/alice@:user_namespace" with parameters:
    """
    all: true
    filter:
    - :account:user:bob@:user_namespace
    - :account:user:charles@:user_namespace
    - :account:user:dave@:user_namespace
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:bob",
      "cucumber:user:charles"
    ]
    """
