@logged-in
Feature: List resources with various types of filtering

  Background:
    Given I create a new resource

  Scenario: Resource list includes a new resource

    The most basic resource listing route returns all resources in an account.

    When I successfully GET "/resources/cucumber"
    Then the resource list should have the new resource

  Scenario: The resource list can be filtered by resource kind.
    When I successfully GET "/resources/cucumber/test-resource"
    Then the resource list should have the new resource

  Scenario: The resource list, when filtered by a different resource kind, does not include the new resource.
    When I successfully GET "/resources/cucumber/uncreated-resource-kind"
    Then the resource list should not have the new resource
