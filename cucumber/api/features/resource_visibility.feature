@logged-in
Feature: Resource visibility rules

  Scenario: Resources from a foreign account are not visible
    Given I create a new resource in a foreign account
    And I successfully GET "/resources/:account"
    Then the resource list should not have the new resource
