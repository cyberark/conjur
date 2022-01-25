@api
@logged-in
Feature: Rules which govern the visibility of resources to roles.

  @acceptance
  Scenario: Resources from a foreign account are not visible without a permission
    Given I create a new resource in a foreign account
    And I create a new user "alice"

    When I login as "alice"
    And I successfully GET "/resources"

    Then the resource list should not include the newest resource

  @acceptance
  Scenario: Resources from a foreign account can be visible
    Given I create a new resource in a foreign account
    And I create a new user "alice"
    And I permit user "alice" to "try" it

    When I login as "alice"
    And I successfully GET "/resources"
    Then the resource list should include the newest resource

    When I successfully GET "/resources/cucumber"
    Then the resource list should not include the newest resource

  @acceptance
  Scenario: Resources without permissions or ownership are not visible
    Given I create a new resource called "probe"
    And I create a new user "alice"

    When I login as "alice"
    And I successfully GET "/resources/cucumber"

    Then the resource list should not include the newest resource

  @smoke
  Scenario: Resources with permissions are visible
    Given I create a new resource called "probe"
    And I create a new user "alice"
    And I permit user "alice" to "try" it

    When I login as "alice"
    And I successfully GET "/resources/cucumber"

    Then the resource list should include the newest resource

  @smoke
  Scenario: Resources with transitive permissions are visible

    Note: A role has a "transitive permission" on a resource if it's a member of a role that has a permission.

    Given I create a new resource called "probe"
    And I create a new user "alice"
    And I permit user "alice" to "try" it

    And I create a new user "bob"
    And I grant user "alice" to user "bob"

    When I login as "bob"
    And I successfully GET "/resources/cucumber"
    Then the HTTP response content type is "application/json"

    Then the resource list should include the newest resource

  @smoke
  Scenario: Owned resources are visible even without explicit permissions
    Given I create a new user "alice"
    And I login as "alice"
    And I create a new resource called "probe"

    When I successfully GET "/resources/cucumber"
    Then the resource list should include the newest resource

  @smoke
  Scenario: Transitively owned resources are visible even without explicit permissions

    Note: a resource is "transitively owned" if the user holds a role that is the owner.

    Given I create a new user "alice"
    And I create a new user "bob"
    And I grant user "alice" to user "bob"

    And I login as "alice"
    And I create a new resource called "probe"

    When I login as "bob"
    Then I can GET "/resources/cucumber/test-resource/probe"
    And I can GET "/resources/cucumber"
    And the resource list should include the newest resource

  @negative @acceptance
  Scenario: Showing a resource without permissions
    If the user doesn't have a permission or ownership of a resource, showing
    that resource should return 404.

    Given I create a new resource called "probe"
    And I create a new user "alice"

    When I login as "alice"
    And I GET "/resources/cucumber/test-resource/probe"

    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Fetching a secret without any permission on it
    If the user doesn't have any permission or ownership of a secret, fetching
    it should return 404 (not 403) even if it exists.

    Given I create a new resource called "probe"
    And I successfully POST "/secrets/cucumber/test-resource/probe" with body:
    """
    v-1
    """
    And I create a new user "alice"

    When I login as "alice"
    And I GET "/secrets/cucumber/test-resource/probe"
    Then the HTTP response status code is 404
