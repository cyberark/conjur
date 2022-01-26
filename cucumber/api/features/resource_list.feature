@api
@logged-in
Feature: List resources with various types of filtering

  Background:
    Given I create 3 new resources

  @smoke
  Scenario: The resource list includes a new resource.

    The most basic resource listing route returns all resources in an account.

    When I successfully GET "/resources/cucumber"
    Then the resource list should include the newest resources

  @smoke
  Scenario: The resource list can be filtered by resource kind.
    Given I create a new "custom" resource
    When I successfully GET "/resources/cucumber/custom"
    Then the resource list should include the newest resource

  @acceptance
  Scenario: The resource list, when filtered by a different resource kind, does not include the newest resource.
    Given I create a new "custom" resource
    When I successfully GET "/resources/cucumber/uncreated-resource-kind"
    Then the resource list should not include the newest resource

  @smoke
  Scenario: The resource list is searched and contains a resource with a matching resource id.
    Given I create a new resource called "target"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @smoke
  Scenario: The resource list is searched and contains a resource with a matching annotation.
    Given I create a new resource
    And I add an annotation value of "target" to the resource
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a period.
    Given I create a new resource called "target.resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a slash separator.
    Given I create a new resource called "target/resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @acceptance
  Scenario: The resource list is searched and the matched resource id contains a dash separator.
    Given I create a new resource called "target-resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  @smoke
  Scenario: The resource list is searched and contains multiple resources with matching resource ids.
    Given I create a new searchable resource called "target_1"
    And I create a new searchable resource called "target_2"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resources

  @smoke
  Scenario: The resource list is limited to a certain number of results.
    When I successfully GET "/resources/cucumber/test-resource?limit=1"
    Then I receive 1 resources

  @negative @acceptance
  Scenario: The resource list cannot be limited with non numeric value
    When I GET "/resources/cucumber/test-resource?limit=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @negative @acceptance
  Scenario: The resource list cannot be limited with zero
    When I GET "/resources/cucumber/test-resource?limit=0"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @negative @acceptance
  Scenario: The resource list cannot be limited with negative integer
    When I GET "/resources/cucumber/test-resource?limit=-10"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @smoke
  Scenario: The resource list is retrieved starting from a specific offset.
    When I successfully GET "/resources/cucumber/test-resource?offset=1"
    Then I receive 2 resources

  @negative @acceptance
  Scenario: The resource list cannot be retrieved starting from a specific offset with non numeric value
    When I GET "/resources/cucumber/test-resource?offset=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."

  @negative @acceptance
  Scenario: The resource list cannot be retrieved starting from a specific offset with negative integer
    When I GET "/resources/cucumber/test-resource?offset=-10"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."

  @smoke
  Scenario: The resource list is retrieved starting from a specific offset and is limited
    When I successfully GET "/resources/cucumber/test-resource?offset=1&limit=1"
    Then I receive 1 resources

  @negative @acceptance
  Scenario: The resource list cannot be retrieved with non numeric limit delimiter
    When I GET "/resources/cucumber/test-resource?offset=1&limit=abc"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'limit' contains an invalid value. 'limit' must be a positive integer."

  @negative @acceptance
  Scenario: The resource list cannot be retrieved with non numeric offset delimiter
    When I GET "/resources/cucumber/test-resource?offset=abc&limit=1"
    Then the HTTP response status code is 422
    And there is an error
    And the error message includes "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."

  @smoke
  Scenario: The resource list is counted.
    When I successfully GET "/resources/cucumber/test-resource?count=true"
    Then I receive a count of 3
