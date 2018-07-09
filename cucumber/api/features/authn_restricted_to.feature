Feature: User and Host authentication can be network restricted

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user
      id: alice
      restricted_to: 176.0.0.1

    - !user
      id: bob
      restricted_to: [ "127.0.0.1", "172.0.0.0/8" ]
    """

  Scenario: Request origin can deny access
    When I authenticate as "alice" with account "cucumber"
    Then the HTTP response status code is 401

  Scenario: When the request origin is correct, then access is allowed
    When I authenticate as "bob" with account "cucumber"
    Then the HTTP response status code is 200
