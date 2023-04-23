@api
Feature: Fetching secrets from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I have host "data/some_host1"
    And I have host "data/some_host2"
    And I have host "data/some_host3"
    And I have host "data/some_host4"
    And I have host "data/some_host5"
    And I have host "other_host1"
    And I have host "database/other_host2"
    And I have a "variable" resource called "other_sec"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-hosts
        - !policy
            id: edge-abcd1234567890
            body:
            - !host
              id: edge-host-abcd1234567890
              annotations:
                authn/api-key: true

    - !grant
      role: !group edge/edge-hosts
      members:
        - !host edge/edge-abcd1234567890/edge-host-abcd1234567890

    - !policy
      id: data
      body:
        - !variable secret1
        - !variable secret2
        - !variable secret3
        - !variable secret4
        - !variable secret5
        - !variable secret6
    """
    And I add the secret value "s1" to the resource "cucumber:variable:data/secret1"
    And I add the secret value "s2" to the resource "cucumber:variable:data/secret2"
    And I add the secret value "s3" to the resource "cucumber:variable:data/secret3"
    And I add the secret value "s4" to the resource "cucumber:variable:data/secret4"
    And I add the secret value "s5" to the resource "cucumber:variable:data/secret5"
    And I log out

  # Slosilo key
  #########
  @acceptance
  Scenario: Fetching key with edge host return 200 OK with json result
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/slosilo_keys/cucumber"
    Then the HTTP response status code is 200
    And the JSON at "slosiloKeys" should have 1 entries
    And the JSON should have "slosiloKeys/0/fingerprint"
    And the JSON at "slosiloKeys/0/fingerprint" should be a string
    And the JSON should have "slosiloKeys/0/privateKey"
    And the JSON at "slosiloKeys/0/privateKey" should be a string

  @negative @acceptance
  Scenario: Fetching hosts with non edge host return 403
    Given I login as "some_user"
    When I GET "/edge/slosilo_keys/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/data/some_host1"
    When I GET "/edge/slosilo_keys/cucumber"
    Then the HTTP response status code is 403
    Given I am the super-user
    When I GET "/edge/slosilo_keys/cucumber"
    Then the HTTP response status code is 403
    #test wrong account name
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/slosilo_keys/cucumber2"
    Then the HTTP response status code is 403


  # Secrets
  #########

  @acceptance @smoke
  Scenario: Fetching all secrets with edge host return 200 OK with json results

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
      {
        "id": "cucumber:variable:data/secret1",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s1",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s2",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s3",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s4",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s5",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret6",
        "owner": "cucumber:policy:data",
        "permissions": []
      }
    ]}
    """

  @negative @acceptance
  Scenario: Fetching secrets with non edge host return 403 error

    Given I login as "some_user"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/data/some_host1"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403
    Given I am the super-user
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403


  @acceptance
  Scenario: Fetching secrets by batch with edge host return right json every batch call

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
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
    ]}
    """
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
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
    ]}
    """
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 1000
    offset: 4
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s5",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret6",
        "owner": "cucumber:policy:data",
        "permissions": []
      }
    ]}
    """

  @acceptance
  Scenario: Fetching secrets by batch with edge host return right number of results

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 2 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 10
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 4 entries
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 6 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 4 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 2 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 6
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 6 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2000
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 6 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 0
    """
    Then the HTTP response status code is 422
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2001
    """
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching secrets count

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I successfully GET "/edge/secrets/cucumber?count=true"
    Then I receive a count of 6

  @acceptance
  Scenario: Fetching secrets count with limit has no effect

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I successfully GET "/edge/secrets/cucumber?count=true&limit=2&offset=0"
    Then I receive a count of 6

  # Hosts
  #######

  @acceptance @smoke
  Scenario: Fetching hosts with edge host return 200 OK

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 200
    And the JSON response at "hosts" should have 5 entries
    And the JSON response should not have "database"
    And the JSON response should not have "other_host"

  @acceptance
  Scenario: Fetching hosts with parameters

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 2
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 2 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 10
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 3 entries
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 5 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 3 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 2 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 5
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 5 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 2000
    """
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 5 entries
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 0
    """
    Then the HTTP response status code is 422
    When I GET "/edge/hosts/cucumber" with parameters:
    """
    limit: 2001
    """
    Then the HTTP response status code is 422

  @acceptance
  Scenario: Fetching hosts count

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I successfully GET "/edge/hosts/cucumber?count=true"
    Then I receive a count of 5

  @acceptance
  Scenario: Fetching hosts count with limit has no effect

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I successfully GET "/edge/hosts/cucumber?count=true&limit=2&offset=0"
    Then I receive a count of 5


  @negative @acceptance
  Scenario: Fetching hosts with non edge host return 403

    Given I login as "some_user"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/data/some_host1"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
    Given I am the super-user
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
