@api
Feature: Check whether a role has a privilege on a resource

  An RBAC transaction involves a role, a privilege, and a resource. A permission
  check determines whether a transaction is allowed or not.

  Background:
    Given I am a user named "charlie"
    Given I create a new "chunky" resource called "bacon"
    And I create a new user "bob"
    And I permit user "bob" to "fry" it

  @smoke
  Scenario: I confirm that I can perform the granted action
    If a role is granted a privilege on a resource, then a permission check will pass.

    Given I save my place in the audit log file for remote
    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    privilege: fry
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * check
      [auth@43868 user="cucumber:user:charlie"]
      [subject@43868 resource="cucumber:chunky:bacon" role="cucumber:user:charlie" privilege="fry"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="check"]
      cucumber:user:charlie successfully checked if they can fry cucumber:chunky:bacon
    """

  @smoke
  Scenario: I confirm that the role can perform the granted action
    If a role is granted a privilege on a resource, then a permission check will pass.

    Given I save my place in the audit log file for remote
    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: fry
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * check
      [auth@43868 user="cucumber:user:charlie"]
      [subject@43868 resource="cucumber:chunky:bacon" role="cucumber:user:bob" privilege="fry"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="check"]
      cucumber:user:charlie successfully checked if cucumber:user:bob can fry cucumber:chunky:bacon
    """

  @smoke
  Scenario: I confirm that the role cannot perform ungranted actions
    If a role is not granted a privilege, then a permission check will fail.

    Given I save my place in the audit log file for remote
    When I GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: freeze
    """
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * * conjur * check
      [auth@43868 user="cucumber:user:charlie"]
      [subject@43868 resource="cucumber:chunky:bacon" role="cucumber:user:bob" privilege="freeze"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="check"]
      cucumber:user:charlie failed to check if cucumber:user:bob can freeze cucumber:chunky:bacon
    """

  @smoke
  Scenario: The new role can confirm that it may perform the granted action

    A role which is authenticated can use `check` parameter to determine whether it
    has a privilege on some resource.

    When I login as "bob"
    Then I can GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    privilege: fry
    """

  @negative @acceptance
  Scenario: I confirm that the non-existing role permission check will fail
    If a role is not existing, then a permission check will fail.

    When I GET "/resources/cucumber/chunky/bacon" with parameters:
    """
    check: true
    role: cucumber:user:bob-not-exists
    privilege: fry
    """
    Then the HTTP response status code is 403

  @acceptance
  Scenario: I confirm that the role cannot perform actions on nonexistent resources

    If permission check is for not existing variable it will fail.

    When I GET "/resources/cucumber/chunky/bacon-not-exists" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: fry
    """
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: I confirm that the role cannot perform actions on resources it doesn't have permission

  If a role is not granted a permission, then a permission check will fail.
    When I create a new "chunky" resource called "bacon-no-permissions"
    And I GET "/resources/cucumber/chunky/bacon-no-permissions" with parameters:
    """
    check: true
    role: cucumber:user:bob
    privilege: fry
    """
    Then the HTTP response status code is 404
