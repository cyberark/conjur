@api
Feature: Fetching secrets from edge endpoint with special characters

  Background:
    Given I create a new user "some_user"
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
    """
    And I add the secret value "s1±" to the resource "cucumber:variable:data/secret1"
    And I add the secret value "s2\" to the resource "cucumber:variable:data/secret2"
    And I add the secret value "s3" to the resource "cucumber:variable:data/secret3"
    And I log out

  #########

  @acceptance @smoke
  Scenario: Fetching all secrets with edge host and Accept-Encoding base64 return 200 OK with json results

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber"
    And I set the "Accept-Encoding" header to "base64"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
      {
        "id": "cucumber:variable:data/secret1",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "czHCsQ==",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "czJc",
        "version": 1
      },
      {
        "id": "cucumber:variable:data/secret3",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "czM=",
        "version": 1
      }
    ]}
    """

  @acceptance
  Scenario: Fetching all secrets with edge host without Accept-Encoding base64 return 500

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 500

  @acceptance
  Scenario: Fetching secret2 with edge host without Accept-Encoding base64 return 200 and json result with the bad behavior of backslash character

    Given I login as "host/edge/edge-abcd1234567890/edge-host-abcd1234567890"
    When I GET "/edge/secrets/cucumber" with parameters:
    """
    limit: 1
    offset: 1
    """
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    {"secrets":[
      {
        "id": "cucumber:variable:data/secret2",
        "owner": "cucumber:policy:data",
        "permissions": [],
        "value": "s2\\",
        "version": 1
      }
    ]}
    """

