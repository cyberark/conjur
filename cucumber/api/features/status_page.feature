@api
Feature: Status page

  The root route is a simple "status page" that verifies that the API is reachable

  @smoke
  Scenario: GET / is reachable.

    When I GET the root route
    Then the status page is reachable
  
  @smoke
  Scenario: GET / with JSON is reachable.

    When I GET the root route with JSON
    Then the status JSON includes the version number
