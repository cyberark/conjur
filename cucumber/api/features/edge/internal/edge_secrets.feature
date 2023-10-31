@api
Feature: Fetching secrets from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I have host "data/some_host2"
    And I have host "data/some_host3"
    And I have host "data/some_host4"
    And I am the super-user
    When I successfully PUT "/policies/cucumber/policy/root" with body:
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
        - !policy
            id: edge-configuration
            body:
              - &edge-variables
                - !variable max-edge-allowed
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
        - !host
              id: some_host1
              annotations:
                authn/api-key: true
        - !permit
          role: !host some_host1
          privilege: [ execute ]
          resource: !variable secret1
        - !permit
          role: !host some_host2
          privilege: [ execute ]
          resource: !variable secret1
        - !permit
          role: !host some_host3
          privilege: [ read ]
          resource: !variable secret1
        - !permit
          role: !host some_host4
          privilege: [ write ]
          resource: !variable secret1
    """
    And I add the secret value "s1" to the resource "cucumber:variable:data/secret1"
    And I add the secret value "s2" to the resource "cucumber:variable:data/secret2"
    And I add the secret value "s3" to the resource "cucumber:variable:data/secret3"
    And I add the secret value "s4" to the resource "cucumber:variable:data/secret4"
    And I add the secret value "s5" to the resource "cucumber:variable:data/secret5"
    And I log out

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
        "permissions": [{
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host1"
               },
               {
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host2"
              }
        ],
        "value": "s1",
        "version": 1,
        "versions": [
        {
          "value": "s1",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s2",
        "version": 1,
        "versions": [
        {
          "value": "s2",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s3",
        "version": 1,
        "versions": [
        {
          "value": "s3",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s4",
        "version": 1,
        "versions": [
        {
          "value": "s4",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s5",
        "version": 1,
        "versions": [
        {
          "value": "s5",
          "version": 1
        }
        ]
      }
    ],
    "failed": []}
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
        "permissions": [{
           "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host1"
               },
               {
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host2"
              }
        ],
        "value": "s1",
        "version": 1,
        "versions": [
        {
          "value": "s1",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s2",
        "version": 1,
        "versions": [
        {
          "value": "s2",
          "version": 1
        }
        ]
      }
    ],
    "failed": []
    }
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
        "version": 1,
        "versions": [
        {
          "value": "s3",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [
        ],
        "value": "s4",
        "version": 1,
        "versions": [
        {
          "value": "s4",
          "version": 1
        }
        ]
      }
    ],
    "failed":[]}
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
        "version": 1,
        "versions": [
        {
          "value": "s5",
          "version": 1
        }
        ]
      }
    ],
    "failed":[]}
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
    And the JSON at "secrets" should have 3 entries
    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    offset: 0
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 5 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    offset: 2
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 3 entries
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
    And the JSON at "secrets" should have 5 entries
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 2000
    """
    Then the HTTP response status code is 200
    And the JSON at "secrets" should have 5 entries
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

  @acceptance
  Scenario: Fetching special characters secret with edge host and Accept-Encoding base64 return 200 OK with json results

    Given I login as "some_user"
    And I add the secret value "s1±\" to the resource "cucumber:variable:data/secret1"
    And I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/edge/secrets/cucumber" with parameters:
  """
  limit: 1
  """
    Then the HTTP response status code is 200
    And the JSON should be:
  """
  {"secrets":[
    {
      "id": "cucumber:variable:data/secret1",
      "owner": "cucumber:policy:data",
      "permissions": [{
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host1"
               },
               {
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host2"
              }
      ],
      "value": "czHCsVw=",
      "version": 2,
        "versions": [
        {
          "value": "czHCsVw=",
          "version": 2
        }
        ]
    }
  ],
  "failed":[]}
  """

  @negative @acceptance
  Scenario: Fetching all secrets with edge host without Accept-Encoding base64 return 200 and I have special character secret

    Given I login as "some_user"
    And I add the secret value "s1±" to the resource "cucumber:variable:data/secret1"
    And I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
      {
       "id": "cucumber:variable:data/secret1",
       "owner": "cucumber:policy:data",
       "permissions": [
       {
         "policy": "cucumber:policy:root",
         "privilege": "execute",
         "resource": "cucumber:variable:data/secret1",
         "role": "cucumber:host:data/some_host1"
       },
       {
         "policy": "cucumber:policy:root",
         "privilege": "execute",
         "resource": "cucumber:variable:data/secret1",
         "role": "cucumber:host:data/some_host2"
       }
       ],
       "value": "s1±",
       "version": 2,
       "versions": [
       {
        "value": "s1±",
        "version": 2
       }
       ]
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s2",
        "version": 1,
        "versions": [
        {
          "value": "s2",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s3",
        "version": 1,
        "versions": [
        {
          "value": "s3",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret4",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s4",
        "version": 1,
        "versions": [
        {
          "value": "s4",
          "version": 1
        }
        ]
      },
      {
        "id": "cucumber:variable:data/secret5",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s5",
        "version": 1,
        "versions": [
        {
          "value": "s5",
          "version": 1
        }
        ]
      }
    ],
    "failed": []}
    """

  @acceptance
  Scenario: Fetching special character secret1 with edge host without Accept-Encoding base64, return 200 and json result with escaping

    Given I login as "some_user"
    And I add the secret value "s1\" to the resource "cucumber:variable:data/secret1"
    And I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
  """
  limit: 1
  """
    Then the HTTP response status code is 200
    And the JSON should be:
  """
  {"secrets":[
    {
      "id": "cucumber:variable:data/secret1",
      "owner": "cucumber:policy:data",
      "permissions": [{
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host1"
               },
               {
                "policy": "cucumber:policy:root",
                "privilege": "execute",
                "resource": "cucumber:variable:data/secret1",
                "role": "cucumber:host:data/some_host2"
              }],
      "value": "s1\\",
      "version": 2,
        "versions": [
        {
          "value": "s1\\",
          "version": 2
        }
        ]
    }
  ],
  "failed":[]}
  """
