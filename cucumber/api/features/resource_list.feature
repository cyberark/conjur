@logged-in
Feature: List resources with various types of filtering

  Scenario: The resource list includes a new resource.
    Given I create a new resource
    When I successfully GET "/resources/cucumber"
    Then the resource list should include the new resource

  Scenario: The resource list can be filtered by resource kind.
    Given I create a new resource
    When I successfully GET "/resources/cucumber/test-resource"
    Then the resource list should include the new resource

  Scenario: The resource list, when filtered by a different resource kind, does not include the new resource.
    Given I create a new resource
    When I successfully GET "/resources/cucumber/uncreated-resource-kind"
    Then the resource list should not include the new resource

  Scenario: The resource list includes many new resources.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber"
    Then the resource list should include the new resources

  Scenario: The resource list is searched and contains a resource with a matching resource id.
    Given I create 3 new resources
    And I create a new resource called "target"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  Scenario: The resource list is searched and contains a resource with a matching annotation.
    Given I create 3 new resources
    And I create a new resource
    And I add an annotation value of "target" to the resource
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  Scenario: The resource list is searched and the matched resource id contains a period.
    Given I create 3 new resources
    And I create a new resource called "target.resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  Scenario: The resource list is searched and the matched resource id contains a slash separator.
    Given I create 3 new resources
    And I create a new resource called "target/resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  Scenario: The resource list is searched and the matched resource id contains a dash separator.
    Given I create 3 new resources
    And I create a new resource called "target-resource"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resource

  Scenario: The resource list is searched and contains multiple resources with matching resource ids.
    Given I create 3 new resources
    And I create a new searchable resource called "target_1"
    And I create a new searchable resource called "target_2"
    When I successfully GET "/resources/cucumber/test-resource?search=target"
    Then the resource list should only include the searched resources

  Scenario: The resource list is filtered by limit.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber/test-resource?limit=1"
    Then I receive 1 resources

  Scenario: The resource list is filtered by offset.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber/test-resource?offset=1"
    Then I receive 2 resources

  Scenario: The resource list is counted.
    Given I create 3 new resources
    When I successfully GET "/resources/cucumber/test-resource?count=true"
    Then I receive a count of 3
