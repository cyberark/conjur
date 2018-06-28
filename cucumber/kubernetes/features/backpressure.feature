Feature: Backpressure in response to load.

  Scenario: Login overload causes a 503 Service Unavailable.
    When I launch many concurrent login requests
    Then at least one response status is 503
