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
    """
    And I log out

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
