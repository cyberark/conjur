@api
Feature: Delete edge

  Background:
    Given I create a new user "some_user"
    And I create a new user "admin_user"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-hosts
        - !group edge-installer-group
        - !policy
          id: edge-configuration
          body:
            - &edge-variables
              - !variable max-edge-allowed
              - !variable edge-cycle-interval
        - !permit
              role: !group edge-hosts
              privileges: [ read, execute ]
              resources: !variable edge-configuration/edge-cycle-interval

    - !group Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      member: !user admin_user
      """
    And I add the secret value "1" to the resource "cucumber:variable:edge/edge-configuration/max-edge-allowed"
    And I set the "Content-Type" header to "application/json"
    And I POST "/edge/cucumber" with body:
    """
    {
      "edge_name": "edgy"
    }
    """
    Then the HTTP response status code is 201


  @smoke @acceptance
  Scenario: Delete edge with admin user returns 204
    Given I login as "admin_user"
    And I save my place in the audit log file for remote
    When I DELETE "/edge/cucumber/edgy"
    Then the HTTP response status code is 204
    And there is an audit record matching:
    """
      <85>1 * * conjur * deleted
      [auth@43868 user="cucumber:user:admin_user"]
      [subject@43868 edge="edgy"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="delete"]
      User cucumber:user:admin_user successfully deleted Edge instance named edgy
    """
    When I set the "Content-Type" header to ""
    And I GET "/edge/cucumber"
    Then the HTTP response status code is 200
    And the JSON should be:
    """
    []
    """

  @negative @acceptance
  Scenario: Delete edge with non admin user return 403
    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I DELETE "/edge/cucumber/edgy"
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <85>1 * * conjur * deleted
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 edge="edgy"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="delete"]
      User cucumber:user:alice failed to delete Edge instance named edgy
    """

  @negative @acceptance
  Scenario: Delete non existing edge returns 404
    Given I login as "admin_user"
    And I save my place in the audit log file for remote
    When I DELETE "/edge/cucumber/edgy1"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <85>1 * * conjur * deleted
      [auth@43868 user="cucumber:user:admin_user"]
      [subject@43868 edge="edgy1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="delete"]
      User cucumber:user:admin_user failed to delete Edge instance named edgy1
    """