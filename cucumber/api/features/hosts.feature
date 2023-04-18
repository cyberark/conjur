@api
Feature: Fetching edge host
  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !group Conjur_Cloud_Admins
    - !user bob
    - !user alice
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
    """


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

  Scenario: Fetching edge host credentials
    Given I login as "alice"
    When I GET "/edge/host/cucumber/edge%2Dhost%2Dabcd1234567891"
    Then the HTTP response status code is 200
    And the HTTP response content type is "text/plain"
    And the HTTP response is base64 encoded