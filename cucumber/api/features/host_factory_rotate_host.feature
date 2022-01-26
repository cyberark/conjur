@api
Feature: Rotate a host api key using the host factory.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: database
      body:
        - !layer users
        - !host-factory
          id: users
          layers: [ !layer users ]
    """
    And I create a host factory token for "database/users"
    And I authorize the request with the host factory token
    And I successfully POST "/host_factories/hosts?id=brand-new-host"
    And I log out
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    []
    """

  @negative @acceptance
  Scenario: The host factory cannot rotate the host api key that previously existed

    If a host role already exists, but there is no corresponding resource to check,
    the host builder will now return 403 forbidden because we cannot verify ownership.

    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: database
      body:
        - !layer users
        - !host-factory
          id: users
          layers: [ !layer users ]
    """
    And I create a host factory token for "database/users"
    And I authorize the request with the host factory token
    And I POST "/host_factories/hosts?id=brand-new-host"
    Then the HTTP response status code is 403

  @smoke
  Scenario: The host factory can rotate the host api key

    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: database
      body:
        - !layer users
        - !host-factory
          id: users
          layers: [ !layer users ]

    - !host
      id: brand-new-host
      owner: !host-factory database/users
    """
    And I create a host factory token for "database/users"
    And I authorize the request with the host factory token
    And I successfully POST "/host_factories/hosts?id=brand-new-host"
    Then the HTTP response status code is 201
    And our JSON should be:
    """
    {
      "annotations" : [],
      "id": "cucumber:host:brand-new-host",
      "owner": "cucumber:host_factory:database/users",
      "policy": "cucumber:policy:root",
      "api_key": "@response_api_key@",
      "permissions": [],
      "restricted_to": []
    }
    """
