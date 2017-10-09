Feature: Status page

  The root route is a simple "status page" that can be used to verify that the API is reachable

  Scenario: GET / returns 200.

    When I GET "/"
    Then the HTTP response status code is 200
    And the html result contains "Conjur CE Status"
