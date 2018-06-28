Feature: Check whether a role has a privilege on a resource

  An RBAC transaction involves a role, a privilege, and a resource. A permission
  check determines whether a transaction is allowed or not.

  Background:
    Given I am a user named "charlie"
    Given I create a new "chunky" resource called "bacon"
    And I create a new user "bob"
    And I permit user "bob" to "fry" it

  Scenario: I confirm that I can perform the granted action

    If a role is granted a privilege on a resource, then a permission check will pass.

    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    privilege: fry
    """

  Scenario: I confirm that the role can perform the granted action

    If a role is granted a privilege on a resource, then a permission check will pass.

    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: fry
    """
    And there is an audit record matching:
    """
      <38>1 * * conjur * check
      [auth@43868 user="cucumber:user:charlie"]
      [subject@43868 role="cucumber:user:bob" resource="cucumber:chunky:bacon"
        privilege="fry"]
      [action@43868 operation="check" result="success"]
      cucumber:user:charlie checked if cucumber:user:bob can fry cucumber:chunky:bacon (success)
    """

  Scenario: I confirm that the role cannot perform ungranted actions

    If a role is not granted a privilege, then a permission check will fail.

    When I GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: freeze
    """
    Then the HTTP response status code is 404

  Scenario: The new role can confirm that it may perform the granted action

    A role which is authenticated can use `check` parameter to determine whether it
    has a privilege on some resource.

    When I login as "bob"
    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    privilege: fry
    """
