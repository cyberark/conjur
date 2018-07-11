Feature: User and Host authentication can be network restricted

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user
      id: alice
      # 176.0.0.1 is an arbitrary subnet that doesn't exist and that
      # doesn't match our actual network to verify that a request origin
      # that doesn't match is unauthorized.
      restricted_to: 176.0.0.1

    - !user
      id: bob
      # For positive origin verification, there are two subnets that need
      # to be allowed:
      #
      # 127.0.0.1   - Allows connections in the local network
      # 172.0.0.0/8 - Allows connections in a docker/docker-compose network
      #               using default network settings
      restricted_to: [ "127.0.0.1", "172.0.0.0/8" ]
    """

  Scenario: Request origin can deny access
    When I authenticate as "alice" with account "cucumber"
    Then the HTTP response status code is 401

  Scenario: When the request origin is correct, then access is allowed
    When I authenticate as "bob" with account "cucumber"
    Then the HTTP response status code is 200
