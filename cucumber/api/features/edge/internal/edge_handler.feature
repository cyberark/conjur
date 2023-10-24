@api
Feature: Edge data endpoint

  Background:
    Given I create a new user "some_user"
    And I create a new user "admin_user"
    And I have host "data/some_host1"
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
    And I add the secret value "3" to the resource "cucumber:variable:edge/edge-configuration/max-edge-allowed"

  @acceptance
  Scenario: Edge start report success emits audit
    Given I login as "admin_user"
    And I set the "Content-Type" header to "application/json"
    And I POST "/edge/cucumber" with body:
    """
    {
      "edge_name": "edgy"
    }
    """
    And the HTTP response status code is 201
    And I save my place in the audit log file for remote
    When I login as the host associated with Edge "edgy"
    And I POST "/edge/data/cucumber?data_type=install" with body:
    """
     { "installation_date" : 1111111 }
    """
    Then the HTTP response status code is 204
    And there is an audit record matching:
    """
     <85>1 * * conjur * installed
     [auth@43868 user="edgy"]
     [subject@43868 edge="edgy"]
     [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
     [action@43868 result="success" operation="install"]
     Edge instance edgy has been installed
    """

  @negative
  Scenario: Edge start report failure emits audit
    Given I login as "admin_user"
    And I set the "Content-Type" header to "application/json"
    And I POST "/edge/cucumber" with body:
    """
    {
      "edge_name": "edgy"
    }
    """
    And the HTTP response status code is 201
    And I save my place in the audit log file for remote
    When I login as the host associated with Edge "edgy"
    And I POST "/edge/data/cucumber?data_type=install" with body:
    """
     { "installation_bad_date" : 1111111 }
    """
    Then the HTTP response status code is 422
    And there is an audit record matching:
    """
     <85>1 * * conjur * installed
     [auth@43868 user="edgy"]
     [subject@43868 edge="edgy"]
     [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
     [action@43868 result="failure" operation="install"]
     Edge instance edgy install failed
    """