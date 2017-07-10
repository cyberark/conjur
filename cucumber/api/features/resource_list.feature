@logged-in
Feature: List resources with various types of filtering

  Scenario: Resource list includes a new resource.
    Given I create a new resource
    When I successfully GET "/resources/cucumber"
    Then the resource list should have the new resource

  Scenario: The resource list can be filtered by resource kind.
    Given I create a new resource
    When I successfully GET "/resources/cucumber/test-resource"
    Then the resource list should have the new resource

  Scenario: The resource list, when filtered by a different resource kind, does not include the new resource.
    Given I create a new resource
    When I successfully GET "/resources/cucumber/uncreated-resource-kind"
    Then the resource list should not have the new resource

  Scenario: Resource list includes many new resources.
    Given I create 5 new resources
    When I successfully GET "/resources/cucumber"
    Then the resource list should have the new resources

  Scenario: Resource list is limited to the given number of items.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber?limit=1"
    Then I receive 1 resources

  Scenario: Resource list is counted.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber?count=true"
    Then I receive a count of 3

  Scenario: Resource list is filtered by offset.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber?offset=1"
    Then I receive 2 resources

  Scenario: Resource list is filtered by search.
    Given I create 3 new resources
    And I create a new resource called "target"
    When I successfully GET "/resources/cucumber?search=target"
    Then the resource list should only include the searched resource



