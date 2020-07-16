Feature: User and Host authentication can be network restricted

  Background:
    Given I am the super-user
    And I load a network-restricted policy


  Scenario: Request origin can deny access
    When I authenticate as "alice" with account "cucumber"
    Then the HTTP response status code is 401

  Scenario: When the request origin is correct, then access is allowed
    When I authenticate as "bob" with account "cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
