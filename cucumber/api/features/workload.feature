@api
Feature: Creating host
  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    - !user eve

    - !policy
      id: data
      owner: !user alice
      body:
      - !policy
        id: db
      - !policy
        id: ephemeral
        body:
        - !policy
          id: hosts

    - !permit
      resource: !policy data/db
      privilege: [ create ]
      role: !user bob

    - !permit
      resource: !policy data/db
      privilege: [ read ]
      role: !user eve
    """

  @smoke
  Scenario: An owner role can create host.
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I successfully POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host1",
      "policy_tree": "data",
      "auth_apikey": "true",
      "annotations": {
        "description": "describe"
      }
    }
    """
    Then our JSON should be:
    """
    {
      "host_id": "host1",
      "policy_tree": "data",
      "annotations": {
        "description": "describe"
      },
      "api_key": "@response_api_key@"
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:host:data/host1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:data" version="1"]
      cucumber:user:alice added resource cucumber:host:data/host1
    """
    When I successfully GET "/resources/cucumber/host/data/host1"
    Then the JSON should be:
    """
    {
      "annotations" : [
        {
          "name": "description",
          "policy": "cucumber:policy:data",
          "value": "describe"
        },
        {
          "name": "authn/api-key",
          "policy": "cucumber:policy:data",
          "value": "true"
         }
      ],
      "id": "cucumber:host:data/host1",
      "owner": "cucumber:policy:data",
      "permissions": [

      ],
      "policy": "cucumber:policy:data",
      "restricted_to": [

      ]
    }
    """

  @smoke
  Scenario: A role with "create" privilege can create host.
    Given I set the "Content-Type" header to "application/json"
    When I login as "bob"
    And I save my place in the audit log file for remote
    And I successfully POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host2",
      "policy_tree": "data/db",
      "annotations": {
        "annotation": "example"
      }
    }
    """
    Then our JSON should be:
    """
    {
      "host_id": "host2",
      "policy_tree": "data/db",
      "annotations": {
        "annotation": "example"
      }
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 resource="cucumber:host:data/db/host2"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:data/db" version="1"]
      cucumber:user:bob added resource cucumber:host:data/db/host2
    """
    When I login as "alice"
    And I successfully GET "/resources/cucumber/host/data/db/host2"
    Then the JSON should be:
    """
    {
      "annotations" : [
        {
          "name": "annotation",
          "policy": "cucumber:policy:data/db",
          "value": "example"
        }
      ],
      "id": "cucumber:host:data/db/host2",
      "owner": "cucumber:policy:data/db",
      "permissions": [

      ],
      "policy": "cucumber:policy:data/db",
      "restricted_to": [

      ]
    }
    """

  @negative @acceptance
  Scenario: A role without correct privilege cannot create host
    Given I set the "Content-Type" header to "application/json"
    When I login as "eve"
    And I save my place in the audit log file for remote
    And I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host3",
      "policy_tree": "data/db",
      "annotations": {
        "annotation": "example"
      }
    }
    """
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:eve"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Forbidden
    """

  @negative @acceptance
  Scenario: API fails on not existent policy
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host4",
      "policy_tree": "data/nonexistent"
    }
    """
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Policy 'data/nonexistent' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Fail on create host that already exists
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I successfully POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host5",
      "policy_tree": "data"
    }
    """
    Then our JSON should be:
    """
    {
      "host_id": "host5",
      "policy_tree": "data"
    }
    """
    And I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host5",
      "policy_tree": "data"
    }
    """
    Then the HTTP response status code is 409
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: host "cucumber:host:data/host5" already exists
    """

  @acceptance
  Scenario: Creating same host id in different policy tree
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I successfully POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host_data",
      "policy_tree": "data"
    }
    """
    Then our JSON should be:
    """
    {
      "host_id": "host_data",
      "policy_tree": "data"
    }
    """
    When I successfully POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host_data",
      "policy_tree": "data/db"
    }
    """
    Then our JSON should be:
    """
    {
      "host_id": "host_data",
      "policy_tree": "data/db"
    }
    """
    When I successfully GET "/resources/cucumber/host/data/db/host_data"
    Then our JSON should be:
    """
    {
      "annotations": [

      ],
      "id": "cucumber:host:data/db/host_data",
      "owner": "cucumber:policy:data/db",
      "permissions": [

      ],
      "policy": "cucumber:policy:data/db",
      "restricted_to": [

      ]
    }
    """

  @negative @acceptance
  Scenario: API fails on not valid host id
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "invalid+host",
      "policy_tree": "data"
    }
    """
    Then the HTTP response status code is 422
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Value provided for parameter id is invalid
    """

  @negative @acceptance
  Scenario: API fails on not valid body
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    And I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host_without_policy"
    }
    """
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Policy '' not found in account 'cucumber'
    """
    When I save my place in the audit log file for remote
    And I POST "/hosts/cucumber" with body:
    """
    {
      "policy_tree": "data"
    }
    """
    Then the HTTP response status code is 422
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Value provided for parameter id is invalid
    """

  @negative @acceptance
  Scenario: API fails on not authenticated user
    Given I set the "Content-Type" header to "application/json"
    And I log out
    When I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host10",
      "policy_tree": "data"
    }
    """
    Then the HTTP response status code is 401

  @negative @acceptance
  Scenario: API fails on creating host under ephemeral branch
    Given I set the "Content-Type" header to "application/json"
    When I login as "alice"
    And I save my place in the audit log file for remote
    When I POST "/hosts/cucumber" with body:
    """
    {
      "host_id": "host_ephemeral",
      "policy_tree": "data/ephemeral/hosts"
    }
    """
    Then the HTTP response status code is 422
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: Value provided for policy data/ephemeral/hosts is invalid
    """
