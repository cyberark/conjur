@api
Feature: Fetching secrets from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I have host "data/some_host1"
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
    """

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
