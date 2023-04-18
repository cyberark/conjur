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
    """

  Scenario: Fetching edge hosts when edge hosts exists
    Given I log in as user "alice"
    When I GET "/edge/edge_hosts/cucumber"
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 0 entries

  Scenario: Fetching edge hosts when 2 edge hosts exists
    Given I log in as user "alice"
    When I GET "/edge/edge_hosts/cucumber"
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
    Then the HTTP response status code is 200
    And the JSON at "hosts" should have 1 entries
    And the JSON at "hosts/0/id" should be a string
    And the JSON at "hosts/0/name" should be a string

