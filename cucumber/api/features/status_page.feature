Feature: Status page

  The root route is a simple "status page" that verifies that the API is reachable

  Scenario: GET / is reachable.

    When I GET the root route
    Then the status page is reachable
