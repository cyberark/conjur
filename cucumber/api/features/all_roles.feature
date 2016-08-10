@logged-in
Feature: Retrieve the recursive expansion of role grants

  If a role A is granted to a role B, then role B is said to "have" role A.
  These role grants are recursive; so that if role B is granted to role C, then
  role C has roles A, B, and C (a role always "has" its own role).

  This recursive expansion of roles is called the role "memberships".

  Memberships are retrieved through the REST API using the `all` query parameter
  to the `GET /roles/:role` route.

  Scenario: The initial memberships of a role is just the role itself.
    Given a new user "bob"
    When I successfully GET "/roles/:account/user/alice@:user_namespace?all"
    Then the JSON should be:
    """
    [
      "cucumber:user:alice"
    ]
    """

  Scenario: A newly granted role is listed in the grantee's memberships.
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

  Scenario: The role memberships list can be filtered.

    The `filter` parameter can be used to select just a subset of the
    role memberships. This is useful for efficiently determining if a role
    has a specific other roles (or roles).

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
