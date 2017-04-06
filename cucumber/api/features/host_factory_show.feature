@logged-in
Feature: Display information about a host factory.

  Background:
    Given a host factory for layer "the-layer"

  Scenario: The host factory displays the normal resource fields, plus
    the list of layers and tokens. 
    
    Given a host factory token
    When I successfully GET "/resources/cucumber/host_factory/the-layer-factory"
    Then the JSON should be:
    """
    {
      "annotations" : [ ],
      "id": "cucumber:host_factory:the-layer-factory",
      "owner": "cucumber:user:admin",
      "permissions": [ ],
      "host_factory_layers": [
        "cucumber:layer:the-layer"
      ],
      "host_factory_tokens": [
        {
          "cidr": [],
          "expiration": "@host_factory_token_expiration@",
          "token": "@host_factory_token_token@"
        }
      ]
    }
    """
