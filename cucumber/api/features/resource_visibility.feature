@logged-in
Feature: Rules which govern the visibility of resources to roles.

  Scenario: Resources from a foreign account are not visible
    Given I create a new resource in a foreign account
    And I successfully GET "/resources/cucumber"
    Then the resource list should not have the new resource
