Feature: Check whether a role has a privilege on a resource

  An RBAC transaction involves a role, a privilege, and a resource. A permission
  check determines whether a transaction is allowed or not.

  Background:
    Given I create a new resource
    And I create a new user "bob"
    And I permit user "bob" to "fry" it

  @logged-in
  Scenario: I confirm that I can perform the granted action

    If a role is granted a privilege on a resource, then a permission check will pass.

    Then I can GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    check: true
    privilege: fry
    """

  @logged-in
  Scenario: I confirm that the role can perform the granted action

    If a role is granted a privilege on a resource, then a permission check will pass.

    Then I can GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: fry
    """

  @logged-in
  Scenario: I confirm that the role cannot perform ungranted actions

    If a role is not granted a privilege, then a permission check will fail.

    When I GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
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
    Then I can GET "/resources/cucumber/:resource_kind/:resource_id" with parameters:
    """
    check: true
    privilege: fry
    """
