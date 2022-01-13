@api
Feature: List roles which have a specific permission on a resource

  The `permitted_roles` query parameter can be used to list all the roles which have
  a specified privilege on some resource.

  Background:
    Given I am a user named "alice"
    And I create a new resource

  @smoke
  Scenario: Initial permitted roles is just the owner, and the roles which have the owner.
    When I successfully GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    permitted_roles: true
    privilege: fry
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:admin",
      "cucumber:user:alice"
    ]
    """

  @smoke
  Scenario: An additional user with the specified privilege is included in the list
    Given I create a new user "bob"
    And I permit user "bob" to "fry" it
    When I successfully GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    permitted_roles: true
    privilege: fry
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:admin",
      "cucumber:user:alice",
      "cucumber:user:bob"
    ]
    """

  @acceptance
  Scenario: An additional user with an unrelated privilege is not included in the list
    Given I create a new user "bob"
    And I permit user "bob" to "freeze" it
    When I successfully GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    permitted_roles: true
    privilege: fry
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:admin",
      "cucumber:user:alice"
    ]
    """

  @smoke
  Scenario: An additional owner role is included in the list
    Given I create a new user "bob"
    And I grant my role to user "bob"
    When I successfully GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    permitted_roles: true
    privilege: fry
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:admin",
      "cucumber:user:alice",
      "cucumber:user:bob"
    ]
    """
