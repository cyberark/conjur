Feature: Create a host using the host factory.

  Background:
    Given a host factory for layer "the-layer"
    And a host factory token
    
  Scenario: The host factory token authenticates and authorizes a request
    to create a new host.

    Given I authorize the request with the host factory token
    When I successfully POST "/host_factories/hosts?id=host-01"
    Then the JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:host-01",
      "owner": "cucumber:host_factory:the-layer-factory",
      "api_key": "@response_api_key@",
      "permissions": []
    }
    """

  @logged-in-admin
  Scenario: Invalid tokens are rejected.

    Given I successfully DELETE "/host_factory_tokens/@host_factory_token_token@"
    And I log out
    And I authorize the request with the host factory token
    When I POST "/host_factories/hosts?id=host-01"
    Then the HTTP response status code is 401
