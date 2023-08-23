@api
Feature: Fetching edge configuration from edge endpoint

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
    And I add the secret value "0" to the resource "cucumber:variable:edge/edge-configuration/max-edge-allowed"
    And I log out

  @negative @acceptance
  Scenario: max edges allowed is permitted only to admins
    Given I login as "admin_user"
    When I GET "/edge/max-allowed/cucumber"
    Then the HTTP response status code is 200
    Given I login as "some_user"
    When I GET "/edge/max-allowed/cucumber"
    Then the HTTP response status code is 403

  @acceptance
  Scenario: max edges allowed get zero value response
    Given I login as "admin_user"
    When I GET "/edge/max-allowed/cucumber"
    Then the text result is:
    """
    0
    """

  @acceptance
  Scenario: max edges allowed get the secret after a value update as admin
    Given I add the secret value "100" to the resource "cucumber:variable:edge/edge-configuration/max-edge-allowed"
    And I login as "admin_user"
    When I GET "/edge/max-allowed/cucumber"
    Then the text result is:
    """
    100
    """

  @acceptance
  Scenario: admin user and other users don't have permission to read max-allowed-edges variable without the endpoint
    # All users don't have any permission - so they can't get the variable
    Given I login as "admin_user"
    When I GET "/secrets/cucumber/variable/edge/edge-configuration/max-edge-allowed"
    Then the HTTP response status code is 404
    Given I login as "some_user"
    When I GET "/secrets/cucumber/variable/edge/edge-configuration/max-edge-allowed"
    Then the HTTP response status code is 404

  @acceptance
  Scenario: admin user and other users don't have permission to change max-allowed-edges variable
    # All users don't have any permission - so they can't set the variable
    Given I login as "admin_user"
    When I POST "/secrets/cucumber/variable/edge/edge-configuration/max-edge-allowed" with body:
    """
    v-1
    """
    Then the HTTP response status code is 404
    Given I login as "some_user"
    When I POST "/secrets/cucumber/variable/edge/edge-configuration/max-edge-allowed" with body:
    """
    v-1
    """
    Then the HTTP response status code is 404