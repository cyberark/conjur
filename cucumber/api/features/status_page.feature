Feature: Status page

  The root route is a simple "status page" that can be used to verify that the API is reachable

  Scenario: GET / should be reachable.

    When I GET the root route
    Then the status page should be reachable
