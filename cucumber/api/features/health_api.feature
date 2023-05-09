@api
Feature: Status page

  The health route is a simple health actuator that verifies that the API status working

  @smoke
  Scenario: GET /health is reachable.

    When I GET the health route
    Then the health route is reachable