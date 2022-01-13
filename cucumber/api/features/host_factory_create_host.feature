@api
Feature: Create a host using the host factory.

  Background:
    Given I create a host factory for layer "the-layer"
    And I create a host factory token

  @smoke
  Scenario: The host factory token authenticates and authorizes a request
    to create a new host.

    Given I authorize the request with the host factory token
    When I successfully POST "/host_factories/hosts?id=host-01"
    Then our JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:host-01",
      "owner": "cucumber:host_factory:the-layer-factory",
      "api_key": "@response_api_key@",
      "permissions": [],
      "restricted_to": []
    }
    """

  @acceptance
  Scenario: Creating a host with parameters in POST body
    Given I authorize the request with the host factory token
    When I successfully POST "/host_factories/hosts" with body:
    """
    id=host-01
    """
    Then our JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:host-01",
      "owner": "cucumber:host_factory:the-layer-factory",
      "api_key": "@response_api_key@",
      "permissions": [],
      "restricted_to": []
    }
    """

  @negative @acceptance
  @logged-in-admin
  Scenario: Invalid tokens are rejected.

    Given I do DELETE "/host_factory_tokens/@host_factory_token@"
    And I log out
    And I authorize the request with the host factory token
    When I POST "/host_factories/hosts?id=host-01"
    Then the HTTP response status code is 401

  @negative @acceptance
  Scenario: Attempting to create a host without id argument
    Given I authorize the request with the host factory token
    When I POST "/host_factories/hosts"
    Then the HTTP response status code is 422
