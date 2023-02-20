@api
Feature: Fetching secrets from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I have host "some_host"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-admins
        - !policy
            id: edge-EDGE_IDENTIFIER
            body:
            - !host
              id: edge-host-EDGE_IDENTIFIER
              annotations:
                authn/api-key: true

    - !grant
      role: !group edge/edge-admins
      members:
        - !host edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER

    - !policy
      id: data
      body:
        - !variable secret1
        - !variable secret2
        - !variable secret3
        - !variable secret4
        - !variable secret5
    """
    And I add the secret value "s1" to the resource "cucumber:variable:data/secret1"
    And I add the secret value "s2" to the resource "cucumber:variable:data/secret2"
    And I add the secret value "s3" to the resource "cucumber:variable:data/secret3"
    And I add the secret value "s4" to the resource "cucumber:variable:data/secret4"
    And I add the secret value "s5" to the resource "cucumber:variable:data/secret5"
    And I log out

  # Secrets
  #########

  @acceptance
  Scenario: Fetching all secrets with edge host return 200 OK with json results

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    [
      {
        "id": "cucumber:variable:data/secret1",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s1",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s2",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s3",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s4",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s5",
        "version": 1
      }
    ]
    """

  @negative @acceptance
  Scenario: Fetching secrets with non edge host return 403 error

    Given I login as "some_user"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/some_host"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403

  @acceptance
  Scenario: Fetching secrets by batch with edge host return right json every batch call

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    [
      {
        "id": "cucumber:variable:data/secret1",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s1",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s2",
        "version": 1
      }
    ]
    """
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    [
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s3",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s4",
        "version": 1
      }
    ]
    """
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 4
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    [
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s5",
        "version": 1
      }
    ]
    """

  @acceptance
  Scenario: Fetching secrets count

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I successfully GET "/edge/secrets/cucumber?count=true"
    Then I receive a count of 5

  # Hosts
  #######

  @acceptance
  Scenario: Fetching hosts with edge host return 200 OK

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 200

  @negative @acceptance
  Scenario: Fetching hosts with non edge host return 403

    Given I login as "some_user"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/some_host"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403

