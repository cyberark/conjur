Feature: Create edge host endpoint

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

    @acceptance
    Scenario: Create edge host return 204 OK
      Given I login as "admin_user"
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 204
      Then Edge name "edgy" data exists in db

    @negative @acceptance
    Scenario: Create edge with existing name return 408
      Given I login as "admin_user"
      When I POST "/edge/create/cucumber/edgy"
      Then the HTTP response status code is 409

    @negative @acceptance
    Scenario: Create edge with non admin_user return 403
      Given I login as "host/data/some_host1"
      When I POST "/edge/create/cucumber/edgy1"
      Then the HTTP response status code is 403
