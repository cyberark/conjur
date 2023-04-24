@api
Feature: Fetching edge host
  Background:
    Given I am the super-user
    And I create a new user "alice"
    And I create a new user "bob"
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !group Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      member: !user alice

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
            - !host
              id: edge-host-abcd1234567891
              annotations:
                authn/api-key: true

    - !grant
      role: !group edge/edge-hosts
      members:
        - !host edge/edge-abcd1234567890/edge-host-abcd1234567890
        - !host edge/edge-abcd1234567890/edge-host-abcd1234567891
    # Create data tree
    - !policy
        id: data
        owner: !group Conjur_Cloud_Admins
        body:
        - !group Conjur_Cloud_Admins
        - !host not-edge-host
    - !grant
      role: !group data/Conjur_Cloud_Admins
      member: !user bob
    """

  @acceptance @smoke
  Scenario: Fetching edge hosts when 2 edge hosts exists
    Given I login as "alice"
    When I GET "/edge/edge-hosts/cucumber"
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 2 entries
    Then the JSON at "hosts" should be:
    """
    [
      {
      "id": "cucumber:host:edge/edge-abcd1234567890/edge-host-abcd1234567890",
      "name": "edge-host-abcd1234567890"
      },
      {
      "id": "cucumber:host:edge/edge-abcd1234567890/edge-host-abcd1234567891",
      "name": "edge-host-abcd1234567891"
      }
    ]
    """

  @negative @acceptance
  Scenario: Fetching edge host without group permission
    Given I login as "bob"
    When I GET "/edge/edge-hosts/cucumber"
    Then the HTTP response status code is 403

  @negative @acceptance
  Scenario: Fetching edge host wrong account
    Given I login as "bob"
    When I GET "/edge/edge-hosts/cucumber1"
    Then the HTTP response status code is 403

  @negative @acceptance
  Scenario: Fetching edge host credentials for not an Edge host
    Given I login as "alice"
    When I GET "/edge/host/cucumber/data%2fnot-edge-host"
    Then the HTTP response status code is 404

  @acceptance @smoke
  Scenario: Fetching edge host credentials
    Given I login as "alice"
    When I GET "/edge/host/cucumber/edge%2Dhost%2Dabcd1234567891"
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/plain"
    And the HTTP response is plain text and base64 encoded

  @negative @acceptance
  Scenario: Fetching edge host credentials without group permission
    Given I login as "bob"
    When I GET "/edge/host/cucumber/edge%2Dhost%2Dabcd1234567891"
    Then the HTTP response status code is 403

  @negative @acceptance
  Scenario: Fetching edge host credentials with wrong account
    Given I login as "bob"
    When I GET "/edge/host/cucumber1/edge%2Dhost%2Dabcd1234567891"
    Then the HTTP response status code is 403
