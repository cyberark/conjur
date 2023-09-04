@api
Feature: Fetching all edges from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I create a new user "admin_user"
    When I am the super-user
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
        - !policy
            id: edge-configuration
            body:
              - &edge-variables
                - !variable max-edge-allowed
    - !grant
      role: !group edge/edge-hosts
      members:
        - !host edge/edge-abcd1234567890/edge-host-abcd1234567890

    - !group Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      member: !user admin_user
    """
    And I log out

  @negative @acceptance
  Scenario: List edges permitted only to admins
    Given I login as "admin_user"
    When I GET "/edge/cucumber"
    Then the HTTP response status code is 200
    Given I login as "some_user"
    When I GET "/edge/cucumber"
    Then the HTTP response status code is 403