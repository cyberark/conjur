Feature: Create edge process

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
    Scenario: Create edge host return 201 OK
      Given I login as "admin_user"
      And I save my place in the audit log file for remote
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 201
      And Edge name "edgy" data exists in db
      And there is an audit record matching:
      """
        <85>1 * * conjur * created
        [auth@43868 user="cucumber:user:admin_user"]
        [subject@43868 edge="edgy"]
        [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
        [action@43868 result="success" operation="create"]
        User cucumber:user:admin_user successfully created new Edge instance named edgy
      """

    @negative @acceptance
    Scenario: Create edge with existing name return 409
      Given I login as "admin_user"
      And I save my place in the audit log file for remote
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 201
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 409
      And there is an audit record matching:
      """
       <85>1 * * conjur * created
       [auth@43868 user="cucumber:user:admin_user"]
       [subject@43868 edge="edgy"]
       [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
       [action@43868 result="failure" operation="create"]
       User cucumber:user:admin_user failed to create new Edge instance named edgy
      """
    @negative @acceptance
    Scenario: Create edge with non admin_user return 403
      Given I login as "host/data/some_host1"
      When I POST "/edge/create/cucumber/edgy1"
      Then the HTTP response status code is 403

    @negative @acceptance
    Scenario: Exceeding max edges allowed return 422
      Given I login as "admin_user"
      When I POST "/edge/create/cucumber/edgy1"
      Then the HTTP response status code is 201
      When I POST "/edge/create/cucumber/edgy2"
      Then the HTTP response status code is 201
      When I POST "/edge/create/cucumber/edgy3"
      Then the HTTP response status code is 201
      When I POST "/edge/create/cucumber/edgy4"
      Then the HTTP response status code is 422

    @acceptance
    Scenario: Script generation success emits audit
      Given I login as "admin_user"
      And I save my place in the audit log file for remote
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 201
      When I GET "/edge/edge-creds/cucumber/edgy"
      Then the HTTP response status code is 200
      And there is an audit record matching:
      """
       <85>1 * * conjur * creds-generated
       [auth@43868 user="cucumber:user:admin_user"]
       [subject@43868 edge="edgy"]
       [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
       [action@43868 result="success" operation="create"]
       User cucumber:user:admin_user successfully generated installation token for Edge named edgy
      """

  @negative
  Scenario: Script generation failure emits audit
    Given I login as "admin_user"
    When I POST "/edge/create/cucumber/edgy"
    Then the HTTP response status code is 201
    When I log out
    And I login as "some_user"
    And I save my place in the audit log file for remote
    When I GET "/edge/edge-creds/cucumber/edgy"
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
     <85>1 * * conjur * creds-generated
     [auth@43868 user="cucumber:user:some_user"]
     [subject@43868 edge="edgy"]
     [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
     [action@43868 result="failure" operation="create"]
     User cucumber:user:some_user failed to generate token for Edge instance edgy
    """

  @acceptance
  Scenario: Edge start report success emits audit
    Given I login as "admin_user"
    And I POST "/edge/create/cucumber/edgy"
    And the HTTP response status code is 201
    And I save my place in the audit log file for remote
    When I login as the host associated with Edge "edgy"
    And I set the "Content-Type" header to "application/json"
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
    And I POST "/edge/create/cucumber/edgy"
    And the HTTP response status code is 201
    And I save my place in the audit log file for remote
    When I login as the host associated with Edge "edgy"
    And I set the "Content-Type" header to "application/json"
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